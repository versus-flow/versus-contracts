// VoteyAuction.cdc
//
// The VoteyAuction contract is an experimental implementation of an NFT Auction on Flow.
//
// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.
//
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc
//

pub contract VoteyAuction {

    // Events
    pub event NewAuctionCollectionCreated(minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64)
    pub event TokenAddedToauctionItems(tokenID: UInt64, startPrice: UFix64)
    pub event TokenStartPriceUpdated(tokenID: UInt64, newPrice: UFix64)
    pub event NewBid(tokenID: UInt64, bidPrice: UFix64)
    pub event TokenPurchased(tokenID: UInt64, price: UFix64)
    pub event NewTokenAvailableForAuction(tokenID: UInt64, startPrice: UFix64)

    pub struct auctionItemsMeta {
        pub(set) var startPrice: UFix64
        pub(set) var currentPrice: UFix64

        init(votes: UInt64, startPrice: UFix64) {
            self.startPrice = startPrice
            self.currentPrice = startPrice
        }
    }

    pub resource interface AuctionPublic {
        pub fun getAuctionItemsPrices(): {UInt64: UFix64}
        pub fun placeBid(
            id: UInt64, 
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&AnyResource{FungibleToken.Receiver}>, 
            collectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        )
    }

    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionItems: @{UInt64: NonFungibleToken.NFT}
        pub var auctionItemsMeta: {UInt64: auctionItemsMeta}

        // Auction Settings
        pub let minimumBidIncrement: UFix64
        pub let auctionLengthInBlocks: UInt64
        pub var auctionStartBlock: UInt64

        // Recipient's Receiver Capabilities
        pub var recipientNFTCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>?
        pub var recipientVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>?

        // Owner's Receiver Capabilities
        pub let ownerNFTCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        pub let ownerVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>

        // Auction Collection's Vault
        pub let bidVault: @FungibleToken.Vault

        init(
            minimumBidIncrement: UFix64,
            auctionLengthInBlocks: UInt64,
            ownerNFTCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>,
            bidVault: @FungibleToken.Vault
        ) {
            self.auctionItems <- {}
            self.auctionItemsMeta = {}
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.auctionStartBlock = UInt64(0)
            self.recipientNFTCollectionCapability = nil
            self.recipientVaultCapability = nil
            self.ownerNFTCollectionCapability = ownerNFTCollectionCapability
            self.ownerVaultCapability = ownerVaultCapability
            self.bidVault <- bidVault
        }

        // addTokenToauctionItems adds a token to the auction queue, sets the start price
        // and sets the vote count to 0
        pub fun addTokenToauctionItems(token: @NonFungibleToken.NFT, startPrice: UFix64) {
            // store the token ID
            let tokenID = token.id

            // set the initial vote count to 0
            self.auctionItemsMeta[tokenID] = auctionItemsMeta(votes: UInt64(0), startPrice: startPrice)

            // add the token to the auction queue
            let oldToken <- self.auctionItems[tokenID] <- token
            destroy oldToken

            emit TokenAddedToauctionItems(tokenID: tokenID, startPrice: startPrice)
        }

        // getauctionItemsPrices 
        pub fun getAuctionItemsPrices(): {UInt64: UFix64} {
            let priceList: {UInt64: UFix64} = {}

            for id in self.auctionItemsMeta.keys {
                priceList[id] = self.auctionItemsMeta[id]!.currentPrice
            }
            
            return priceList
        }

        // settleAuction sends the auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleAuction(_ id: UInt64) {
            pre {
                self.recipientNFTCollectionCapability != nil:
                    "Recipient's NFT receiver capability is invalid"
            }
                
                // get the token meta data
                let tokenMeta = self.auctionItemsMeta[id]??
                    panic("no meta data for current auction item. we broken!")
                
                if tokenMeta.currentPrice == tokenMeta.startPrice {
                    self.returnAuctionItemToOwner(id)
                    log("No bids nothing to settle")
                    return 
                }

                    if let purchasedToken <- self.auctionItems.remove(key: id) {
                        
                        //... borrow a reference to the highest bidder's NFT collection receiver
                        let recipientNFTCollectionRef = self.recipientNFTCollectionCapability!.borrow()!
                        
                        //... send the NFT to the highest bidder
                        recipientNFTCollectionRef.deposit(token: <-purchasedToken)
                        
                        //... borrow a reference to the owner's Vault
                        let ownerVaultRef = self.ownerVaultCapability.borrow()!

                        //... send the FTs to the Auction Owner
                        let bidVaultTokens <- self.bidVault.withdraw(amount: self.bidVault.balance)
                        ownerVaultRef.deposit(from:<-bidVaultTokens)

                        emit TokenPurchased(tokenID: id, price: tokenMeta.currentPrice)

                    } 
  
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(
            id: UInt64, 
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&AnyResource{FungibleToken.Receiver}>, 
            collectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        ) 
            {
            pre {
                id != nil:
                    "there is no item to bid on"
                bidTokens.balance - self.auctionItemsMeta[id]!.currentPrice >= self.minimumBidIncrement:
                    "bid amount must be larger than the minimum bid increment"
                vaultCap != nil:
                    "Bidder's Vault receiver capability is invalid"
                collectionCap != nil:
                    "Bidder's NFT Collection capability is invalid"
            }

            // get the meta data for the current token
            let currentTokenMeta = self.auctionItemsMeta[id]!

            // release any previously held bid tokens
            self.releasePreviousBid()

            // Store the new bidder's tokens
            self.bidVault.deposit(from:<-bidTokens)

            // Update the current price of the token
            currentTokenMeta.currentPrice = self.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            self.recipientVaultCapability = vaultCap
            self.recipientNFTCollectionCapability = collectionCap

            emit NewBid(tokenID: id, bidPrice: currentTokenMeta.currentPrice)
        }

        // releasePreviousBid returns the outbid user's tokens to
        // their vault receiver
        pub fun releasePreviousBid() {
            // If there was a previous bidder...
            if var recipientVaultCapability = self.recipientVaultCapability {
                //... send the previous bidder's tokens back
                let oldBalance <- self.bidVault.withdraw(amount: self.bidVault.balance)
                
                //... borrow a reference to the recipient's Vault receiver
                let recipientVaultRef = self.recipientVaultCapability!.borrow()!

                //.. deposit the tokens in the recipient's Vault
                recipientVaultRef.deposit(from:<-oldBalance)
            }
        }

        pub fun returnAuctionItemToOwner(_ id: UInt64) {

            // borrow a reference to the auction owner's NFT Collection
            let ownerCollectionRef = self.ownerNFTCollectionCapability.borrow()!

            // deposit the NFT innto owner's collection
            ownerCollectionRef.deposit(token:<-self.auctionItems.remove(key: id)!)
            
            // clear the NFT's meta data from the auction queue
            self.auctionItemsMeta[id] = nil
        }

        destroy() {
            for id in self.auctionItems.keys {
                self.returnAuctionItemToOwner(id)
            }

            // return bidToken balance to the bidder
            self.releasePreviousBid()

            // destroy the empty resources
            destroy self.auctionItems
            destroy self.bidVault
        }
    }

    // createAuctionCollection returns a new AuctionCollection resource to the caller
    pub fun createAuctionCollection(
        minimumBidIncrement: UFix64,
        auctionLengthInBlocks: UInt64,
        ownerNFTCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
        ownerVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>,
        bidVault: @FungibleToken.Vault
    ): @AuctionCollection {

        let auctionCollection <- create AuctionCollection(
            minimumBidIncrement: minimumBidIncrement,
            auctionLengthInBlocks: auctionLengthInBlocks,
            ownerNFTCollectionCapability: ownerNFTCollectionCapability,
            ownerVaultCapability: ownerVaultCapability,
            bidVault: <-bidVault
        )

        emit NewAuctionCollectionCreated(minimumBidIncrement: minimumBidIncrement, auctionLengthInBlocks: auctionLengthInBlocks)

        return <- auctionCollection
    }

    init() {
        log("Auction contract deployed")
    }   
}
 