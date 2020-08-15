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
        access(contract) fun sendNFT(_ capability: Capability<&{NonFungibleToken.CollectionPublic}>) {
            // borrow a reference to the owner's NFT receiver
            if let collectionRef = capability.borrow() {
                let NFT <- self.withdrawNFT()
                // deposit the token into the owner's collection
                collectionRef.deposit(token: <-NFT)
            } else {
                log("sendNFT(): unable to borrow collection ref")
                log(capability)
            }
        }

        access(contract) fun sendBidTokens(_ capability: Capability<&{FungibleToken.Receiver}>) {
            // borrow a reference to the owner's NFT receiver
            if let vaultRef = capability.borrow() {
                let bidVaultRef = &self.bidVault as &FungibleToken.Vault
                vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
            } else {
                log("sendBidTokens(): couldn't get vault ref")
                log(capability)
            }
        }

        destroy() {
            self.sendNFT(self.meta.ownerCollectionCap)
            
            if let vaultCap = self.meta.recipientVaultCap {
                self.sendBidTokens(self.meta.recipientVaultCap!)
            }

            destroy self.NFT
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
        pub(set) var auctionCompleted: Bool

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
            self.auctionCompleted = false
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
                if itemRef.meta.auctionCompleted == false {
                    priceList[id] = itemRef.meta.currentPrice
                }
            }
            
            return priceList
        }

        // settleAuction sends the auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleAuction(_ id: UInt64) {
            let itemRef = &self.auctionItems[id] as &AuctionItem
            let itemMeta = itemRef.meta

            if itemMeta.auctionCompleted {
                log("this auction is already settled")
                return
            }

            if itemRef.NFT == nil {
                log("auction doesn't exist")
                return
            }

            // check if the auction has expired
            if self.isAuctionExpired(id) == false {
                log("Auction has not completed yet")
                return
            }
                
            // return if there are no bids to settle
            if itemMeta.currentPrice == itemMeta.startPrice {
                self.returnAuctionItemToOwner(id)
                log("No bids. Nothing to settle")
                return
            }            

            self.exchangeTokens(id)

            itemMeta.auctionCompleted = true
            
            emit AuctionSettled(tokenID: id, price: itemMeta.currentPrice)
            
            if let item <- self.auctionItems.remove(key: id) {
                item.meta = itemMeta
                self.auctionItems[id] <-! item
            }
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
            
            if itemRef.NFT == nil {
                log("auction doesn't exist")
                return
            }
            
            let itemMeta = itemRef.meta

            itemRef.sendNFT(itemMeta.recipientCollectionCap)
            itemRef.sendBidTokens(itemMeta.ownerVaultCap)
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

            if itemMeta.auctionCompleted {
                panic("auction has already completed")
            }

            if bidTokens.balance < itemMeta.minimumBidIncrement {
                panic("bid amount be larger than minimum bid increment")
            }
            
            if itemRef.bidVault.balance != UFix64(0) {
                if let vaultCap = itemMeta.recipientVaultCap {
                    itemRef.sendBidTokens(itemMeta.recipientVaultCap!)
                } else {
                    panic("unable to get recipient Vault capability")
                }
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
            let itemRef = &self.auctionItems[id] as &AuctionItem
            let itemMeta = itemRef.meta
            // release the bidTokens from the vault back to the bidder
            if let vaultCap = itemMeta.recipientVaultCap {
                itemRef.sendBidTokens(itemMeta.recipientVaultCap!)
            } else {
                log("unable to get vault capability")
            }
        }

        // TODO: I don't think we need this... this should already happen
        // when the resource gets destroyed
        //
        // returnAuctionItemToOwner releases any bids and returns the NFT
        // to the owner's Collection
        pub fun returnAuctionItemToOwner(_ id: UInt64) {
            let itemRef = &self.auctionItems[id] as &AuctionItem
            let itemMeta = itemRef.meta
            
            // release the bidder's tokens
            self.releasePreviousBid(id)
            
            // deposit the NFT into the owner's collection
            itemRef.sendNFT(itemMeta.ownerCollectionCap)

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
 