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
// Acct 1 - 0x01cf0e2f2f715450 - NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - DemoToken.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - Rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - Auction.cdc
//

pub contract VoteyAuction {

    // The total amount of AuctionItems that have been created
    pub var totalAuctions: UInt64

    // Events
    pub event NewAuctionCollectionCreated(minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64)
    pub event TokenAddedToAuctionItems(tokenID: UInt64, startPrice: UFix64)
    pub event TokenStartPriceUpdated(tokenID: UInt64, newPrice: UFix64)
    pub event NewBid(tokenID: UInt64, bidPrice: UFix64)
    pub event AuctionSettled(tokenID: UInt64, price: UFix64)

    // AuctionItem contains the Resources and metadata for a single auction
    pub resource AuctionItem {
        
        // Resources
        pub(set) var NFT: @NonFungibleToken.NFT?
        pub let bidVault: @FungibleToken.Vault

        // Metadata
        pub(set) var meta: ItemMeta

        init(
            NFT: @NonFungibleToken.NFT,
            bidVault: @FungibleToken.Vault,
            meta: ItemMeta
        ) {
            self.NFT <- NFT
            self.bidVault <- bidVault
            self.meta = meta

            VoteyAuction.totalAuctions = VoteyAuction.totalAuctions + UInt64(1)
        }

        // depositBidTokens deposits the bidder's tokens into the AuctionItem's Vault
        pub fun depositBidTokens(vault: @FungibleToken.Vault) {
            self.bidVault.deposit(from: <-vault)
        }

        // withdrawNFT removes the NFT from the AuctionItem and returns it to the caller
        pub fun withdrawNFT(): @NonFungibleToken.NFT {
            let NFT <- self.NFT <- nil
            return <- NFT!
        }

        // updateRecipientVaultCap updates the bidder's Vault capability, providing the
        // us with a way to return their FungibleTokens
        access(contract) fun updateRecipientVaultCap(cap: Capability<&{FungibleToken.Receiver}>) {
            let meta = self.meta
            meta.recipientVaultCap = cap
            self.meta = meta
        }

        // returnOwnerNFT returns the NFT to the owner's Collection
        access(contract) fun returnOwnerNFT(token: @NonFungibleToken.NFT) {
            // borrow a reference to the owner's NFT receiver
            let NFTReceiver = self.meta.ownerCollectionCap.borrow()!

            // deposit the token into the owner's collection
            NFTReceiver.deposit(token: <-token)
        }

        // releaseBidderTokens returns the bidder's FungibleTokens to their Vault
        access(contract) fun releaseBidderTokens() {
            pre {
                self.meta.recipientVaultCap != nil: "There is no recipient to release the tokens to"
            }

            // return home early if the Vault is empty
            if self.bidVault.balance == UFix64(0) { return }

            // withdraw the entire token balance from bidVault
            let bidTokens <- self.bidVault.withdraw(amount: self.bidVault.balance)

            // borrow a reference to the bidder's Vault receiver
            let vaultRef = self.meta.recipientVaultCap!.borrow()
            
            // return the bidTokens to the bidder's Vault
            vaultRef!.deposit(from:<-bidTokens)
        }

        destroy() {
            self.returnOwnerNFT(token: <-self.NFT!)
            self.releaseBidderTokens()
            destroy self.bidVault
        }
    }

    // ItemMeta contains the metadata for an AuctionItem
    pub struct ItemMeta {

        // Auction Settings
        pub let auctionID: UInt64
        pub let minimumBidIncrement: UFix64
        pub let auctionLengthInBlocks: UInt64

        // Auction State
        pub(set) var startPrice: UFix64
        pub(set) var currentPrice: UFix64
        pub(set) var auctionStartBlock: UInt64

        // Recipient's Receiver Capabilities
        pub(set) var recipientCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        pub(set) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?

        // Owner's Receiver Capabilities
        pub let ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        pub let ownerVaultCap: Capability<&{FungibleToken.Receiver}>

        init(
            minimumBidIncrement: UFix64,
            auctionLengthInBlocks: UInt64,
            startPrice: UFix64, 
            auctionStartBlock: UInt64,
            ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            ownerVaultCap: Capability<&{FungibleToken.Receiver}>
        ) {
            self.auctionID = VoteyAuction.totalAuctions + UInt64(1)
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.startPrice = startPrice
            self.currentPrice = startPrice
            self.auctionStartBlock = auctionStartBlock
            self.recipientCollectionCap = ownerCollectionCap
            self.recipientVaultCap = ownerVaultCap
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
        }
    }

    // AuctionPublic is a resource interface that restricts users to
    // retreiving the auction price list and placing bids
    pub resource interface AuctionPublic {
        pub fun getAuctionPrices(): {UInt64: UFix64}
        pub fun placeBid(
            id: UInt64, 
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        )
    }

    // AuctionCollection contains a dictionary of AuctionItems and provides
    // methods for manipulating the AuctionItems
    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionItems: @{UInt64: AuctionItem}
        
        init() {
            self.auctionItems <- {}
        }

        // addTokenToauctionItems adds an NFT to the auction items and sets the meta data
        // for the auction item
        pub fun addTokenToAuctionItems(token: @NonFungibleToken.NFT, minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64, startPrice: UFix64, bidVault: @FungibleToken.Vault, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, vaultCap: Capability<&{FungibleToken.Receiver}>) {
            
            
            // create a new auction meta resource
            let meta = ItemMeta(
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: auctionLengthInBlocks,
                startPrice: startPrice,
                auctionStartBlock: getCurrentBlock().height,
                ownerCollectionCap: collectionCap,
                ownerVaultCap: vaultCap
            )
            
            // create a new auction items resource container
            let item <- create AuctionItem(
                NFT: <-token,
                bidVault: <-bidVault,
                meta: meta
            )

            let id = item.meta.auctionID

            // update the auction items dictionary with the new resources
            let oldItem <- self.auctionItems[id] <- item
            destroy oldItem

            emit TokenAddedToAuctionItems(tokenID: id, startPrice: startPrice)
        }

        // getAuctionPrices returns a dictionary of available NFT IDs with their current price
        pub fun getAuctionPrices(): {UInt64: UFix64} {
            pre {
                self.auctionItems.keys.length > 0: "There are no auction items"
            }

            let priceList: {UInt64: UFix64} = {}

            for id in self.auctionItems.keys {
                let itemRef = &self.auctionItems[id] as? &AuctionItem
                priceList[id] = itemRef.meta.currentPrice
            }
            
            return priceList
        }

        // settleAuction sends the auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleAuction(_ id: UInt64) {

            // check if the auction has expired
            if self.isAuctionExpired(id) == false {
                log("Auction has not completed yet")
                return
            }

            let itemRef = &self.auctionItems[id] as? &AuctionItem
            let itemMeta = itemRef.meta
                
            // return if there are no bids to settle
            if itemMeta.currentPrice == itemMeta.startPrice {
                self.returnAuctionItemToOwner(id)
                log("No bids. Nothing to settle")
                return
            }

            self.exchangeTokens(id)
        }

        // isAuctionExpired returns true if the auction has exceeded it's length in blocks,
        // otherwise it returns false
        pub fun isAuctionExpired(_ id: UInt64): Bool {
            let itemRef = &self.auctionItems[id] as &AuctionItem
            let itemMeta = itemRef.meta

            let auctionLength = itemMeta.auctionLengthInBlocks
            let startBlock = itemMeta.auctionStartBlock 
            let currentBlock = getCurrentBlock()
            
            if currentBlock.height - startBlock > auctionLength {
                return true
            } else {
                return false
            }
        }

        // exchangeTokens sends the purchased NFT to the buyer and the bidTokens to the seller
        pub fun exchangeTokens(_ id: UInt64) {
         
            let itemRef = &self.auctionItems[id] as &AuctionItem

            if itemRef == nil {
                panic("Trying to exchange an NFT that doesn't exist!")
            }

            let itemMeta = itemRef.meta
            
            // log(itemRef)
            // log(itemMeta)

            // send the purchased NFT to the highest bidder
            if let collectionPublic = itemMeta.recipientCollectionCap.borrow() {
                collectionPublic.deposit(token: <- itemRef.withdrawNFT())
            } else {
                panic("could not borrow recipient collection reference")
            }
              
            // send the fungible tokens to the auction owner
            if let ownerVaultRef = itemMeta.ownerVaultCap.borrow() {
                let bidVaultTokens <- itemRef.bidVault.withdraw(amount: itemRef.bidVault.balance)
                ownerVaultRef.deposit(from:<-bidVaultTokens)
            } else {
                panic("could not borrow owner vault reference")
            }

            emit AuctionSettled(tokenID: id, price: itemMeta.currentPrice)
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(id: UInt64, bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) 
            {
            pre {
                self.auctionItems[id] != nil:
                    "NFT doesn't exist"
            }

            // Get the auction item resources
            let itemRef = &self.auctionItems[id] as &AuctionItem
            let itemMeta = itemRef.meta

            if bidTokens.balance < itemMeta.minimumBidIncrement {
                panic("bid amount be larger than minimum bid increment")
            }
            
            if itemRef.bidVault.balance != UFix64(0) {
                itemRef.releaseBidderTokens()
            }

            // Update the auction item
            itemRef.depositBidTokens(vault: <-bidTokens)
            itemRef.updateRecipientVaultCap(cap: vaultCap)

            // Update the current price of the token
            itemMeta.currentPrice = itemRef.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            itemMeta.recipientCollectionCap = collectionCap

            itemRef.meta = itemMeta

            emit NewBid(tokenID: id, bidPrice: itemMeta.currentPrice)
        }

        // releasePreviousBid returns the outbid user's tokens to
        // their vault receiver
        pub fun releasePreviousBid(_ id: UInt64) {
            // get a reference to the auction items resources
            let auctionItem = &self.auctionItems[id] as &AuctionItem
            // release the bidTokens from the vault back to the bidder
            auctionItem.releaseBidderTokens()
        }

        // TODO: I don't think we need this... this should already happen
        // when the resource gets destroyed
        //
        // returnAuctionItemToOwner releases any bids and returns the NFT
        // to the owner's Collection
        pub fun returnAuctionItemToOwner(_ id: UInt64) {
            let itemRef = &self.auctionItems[id] as &AuctionItem
            let itemMeta = itemRef.meta
            
            let ownerCollectionRef = itemMeta.ownerCollectionCap.borrow() ?? panic("Could not borrow ownerCollectionCap")
            
            // release the bidder's tokens
            itemRef.releaseBidderTokens()
            
            // withdraw the NFT from the auction collection
            let NFT <-itemRef.withdrawNFT()
            
            // deposit the NFT into the owner's collection
            itemRef.returnOwnerNFT(token:<-NFT)

            // clear the NFT's meta data
            let oldItem <- self.auctionItems[id] <- nil
            destroy oldItem
        }

        destroy() {
            for id in self.auctionItems.keys {
                self.returnAuctionItemToOwner(id)
            }
            // destroy the empty resources
            destroy self.auctionItems
        }
    }

    // createAuctionCollection returns a new AuctionCollection resource to the caller
    pub fun createAuctionCollection(): @AuctionCollection {
        let auctionCollection <- create AuctionCollection()
        return <- auctionCollection
    }

    init() {
        self.totalAuctions = UInt64(0)
    }   
}
 