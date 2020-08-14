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
    pub event TokenAddedToAuctionItems(tokenID: UInt64, startPrice: UFix64)
    pub event TokenStartPriceUpdated(tokenID: UInt64, newPrice: UFix64)
    pub event NewBid(tokenID: UInt64, bidPrice: UFix64)
    pub event AuctionSettled(tokenID: UInt64, price: UFix64)

    pub resource auctionItemResources {

        pub(set) var NFT: @NonFungibleToken.NFT?
        pub let bidVault: @FungibleToken.Vault

        // Recipient's Receiver Capabilities
        pub var recipientVaultCap: Capability<&AnyResource{FungibleToken.Receiver}>?

        // Owner NFT Receiver Capability
        pub let ownerNFTReceiverCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>

        init(
            NFT: @NonFungibleToken.NFT,
            bidVault: @FungibleToken.Vault,
            ownerNFTReceiverCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        ) {
            self.NFT <- NFT
            self.bidVault <- bidVault
            self.recipientVaultCap = nil
            self.ownerNFTReceiverCap = ownerNFTReceiverCap
        }

        pub fun depositBidTokens(vault: @FungibleToken.Vault) {
            self.bidVault.deposit(from: <-vault)
        }

        pub fun withdrawNFT(): @NonFungibleToken.NFT {
            let NFT <- self.NFT <- nil
            return <- NFT!
        }

        access(contract) fun updateRecipientVaultCap(cap: Capability<&AnyResource{FungibleToken.Receiver}>) {
            self.recipientVaultCap = cap
        }

        access(contract) fun returnOwnerNFT(token: @NonFungibleToken.NFT) {
            // borrow a reference to the owner's NFT receiver
            let NFTReceiver = self.ownerNFTReceiverCap.borrow()!

            // deposit the token into the owner's collection
            NFTReceiver.deposit(token: <-token)
        }

        access(contract) fun releaseBidderTokens() {
            pre {
                self.recipientVaultCap != nil: "There is no recipient to release the tokens to"
            }

            // withdraw the entire token balance from bidVault
            let bidTokens <- self.bidVault.withdraw(amount: self.bidVault.balance)

            // borrow a reference to the bidder's Vault receiver
            let vaultRef = self.recipientVaultCap!.borrow()
            
            // return the bidTokens to the bidder's Vault
            vaultRef!.deposit(from:<-bidTokens)
        }

        destroy() {
            self.returnOwnerNFT(token: <-self.NFT!)
            self.releaseBidderTokens()
            destroy self.bidVault
        }
    }

    pub struct auctionItemMeta {

        // Auction Settings
        pub let minimumBidIncrement: UFix64
        pub let auctionLengthInBlocks: UInt64

        // Auction State
        pub(set) var startPrice: UFix64
        pub(set) var currentPrice: UFix64
        pub(set) var auctionStartBlock: UInt64

        // Recipient's Receiver Capabilities
        pub(set) var recipientCollectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        pub(set) var recipientVaultCap: Capability<&AnyResource{FungibleToken.Receiver}>?

        init(
            minimumBidIncrement: UFix64,
            auctionLengthInBlocks: UInt64,
            startPrice: UFix64, 
            auctionStartBlock: UInt64,
            recipientCollectionCap :Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        ) {
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.startPrice = startPrice
            self.currentPrice = startPrice
            self.auctionStartBlock = auctionStartBlock
            self.recipientCollectionCap = recipientCollectionCap
            self.recipientVaultCap = nil
        }
    }

    pub resource interface AuctionPublic {
        pub fun getAuctionPrices(): {UInt64: UFix64}
        pub fun placeBid(
            id: UInt64, 
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&AnyResource{FungibleToken.Receiver}>, 
            collectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        )
    }

    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionItems: @{UInt64: auctionItemResources}
        pub var auctionItemsMeta: {UInt64: auctionItemMeta}

        // Owner's Receiver Capabilities
        pub let ownerNFTReceiverCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        pub let ownerVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>
        
        init(
            ownerNFTReceiverCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>
        ) {
            self.auctionItems <- {}
            self.auctionItemsMeta = {}
            self.ownerNFTReceiverCap = ownerNFTReceiverCap
            self.ownerVaultCapability = ownerVaultCapability
        }

        // addTokenToauctionItems adds an NFT to the auction items and sets the meta data
        // for the auction item
        pub fun addTokenToAuctionItems(token: @NonFungibleToken.NFT, minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64, startPrice: UFix64, bidVault: @FungibleToken.Vault) {
            // store the token ID
            let tokenID = token.id

            // create a new auction items resource container
            let auctionItemResources <- create auctionItemResources(
                NFT: <-token,
                bidVault: <-bidVault,
                ownerNFTReceiverCap: self.ownerNFTReceiverCap
            )

            // update the auction items dictionary with the new resources
            let oldItems <- self.auctionItems[tokenID] <- auctionItemResources
            destroy oldItems

            // create a new auction meta resource
            let newAuctionMeta = auctionItemMeta(
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: auctionLengthInBlocks,
                startPrice: startPrice,
                auctionStartBlock: getCurrentBlock().height,
                recipientCollectionCap: self.ownerNFTReceiverCap 
            )

            // update the NFT meta dictionary
            self.auctionItemsMeta[tokenID] = newAuctionMeta

            emit TokenAddedToAuctionItems(tokenID: tokenID, startPrice: startPrice)
        }

        // getAuctionPrices returns a dictionary of available NFT IDs with their current price
        pub fun getAuctionPrices(): {UInt64: UFix64} {
            pre {
                self.auctionItemsMeta.keys.length > 0: "There are no auction items"
            }

            let priceList: {UInt64: UFix64} = {}

            /*
            for id in self.auctionItems.keys {
                let item = &self.auctionItems[id] as &auctionItemResources
                let bidVault = &item.bidVault as &FungibleToken.Vault

                let balance = bidVault.balance
                log("Balance for")
                log(id)
                log(balance)

                log("NFT capability")
                log(item.recipientVaultCap)
            } */

            for id in self.auctionItemsMeta.keys {
                let settings=self.auctionItemsMeta[id]!
                //log("price:id")
                //log(id)
                //log(settings)
                priceList[id] = settings.currentPrice
            }
            
            return priceList
        }

        // settleAuction sends the auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleAuction(_ id: UInt64) {
            pre {
                self.auctionItemsMeta[id]!.recipientCollectionCap != nil:
                    "Recipient's NFT receiver capability is invalid"
            }

            // check if the auction has expired
            if self.isAuctionExpired(id) == false {
                log("Auction has not completed yet")
                return
            }
            
            // get the token meta data, panic if there is no data for the token
            let tokenMeta = self.auctionItemsMeta[id]??
                panic("no meta data for current auction item. we broken!")
                
            // return if there are no bids to settle
            if tokenMeta.currentPrice == tokenMeta.startPrice {
                self.returnAuctionItemToOwner(id)
                log("No bids. Nothing to settle")
                return
            }

            self.exchangeTokens(id)
        }

        // isAuctionExpired returns true if the auction has exceeded it's length in blocks,
        // otherwise it returns false
        pub fun isAuctionExpired(_ id: UInt64): Bool {
            let itemMeta = self.auctionItemsMeta[id] ?? panic("Could not find item meta")
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
         
            let purchasedTokenResources = &self.auctionItems[id] as &auctionItemResources

            if purchasedTokenResources == nil {
                panic("Trying to exchange an NFT that doesn't exist!")
            }

            let itemMeta = self.auctionItemsMeta[id] ?? panic("cannot fetch item")

            let itemPrice = itemMeta.currentPrice

            let recipientCollectionRef = itemMeta.recipientCollectionCap
            
            // send the purchased NFT to the highest bidder
            if let collectionPublic = recipientCollectionRef.borrow() {
                collectionPublic.deposit(token: <- purchasedTokenResources.withdrawNFT())
            } else {
                panic("could not borrow recipient collection reference")
            }

            //  log(purchasedTokenResources)
            //  log(itemMeta)
              
            // send the fungible tokens to the auction owner
            if let ownerVaultRef = self.ownerVaultCapability.borrow() {
                let bidVaultTokens <- purchasedTokenResources.bidVault.withdraw(amount: purchasedTokenResources.bidVault.balance)
                ownerVaultRef.deposit(from:<-bidVaultTokens)
            } else {
                panic("could not borrow owner vault reference")
            }

            emit AuctionSettled(tokenID: id, price: itemPrice)
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(id: UInt64, bidTokens: @FungibleToken.Vault, vaultCap: Capability<&AnyResource{FungibleToken.Receiver}>, collectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>) 
            {
            pre {
                self.auctionItems[id] != nil:
                    "NFT doesn't exist"
                bidTokens.balance - self.auctionItemsMeta[id]!.currentPrice >= self.auctionItemsMeta[id]!.minimumBidIncrement:
                    "bid amount must be larger than the minimum bid increment"
            }

            // Get the auction item resources
            let itemsRef = &self.auctionItems[id] as &auctionItemResources
            
            if(itemsRef.recipientVaultCap != nil) {
                itemsRef.releaseBidderTokens()
            }
            // Update the auction item
            itemsRef.depositBidTokens(vault: <-bidTokens)
            itemsRef.updateRecipientVaultCap(cap: vaultCap)

            // get the meta data for the current token
            let currentTokenMeta = self.auctionItemsMeta[id]!

            // Update the current price of the token
            currentTokenMeta.currentPrice = itemsRef.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            currentTokenMeta.recipientCollectionCap = collectionCap

            self.auctionItemsMeta[id]=currentTokenMeta

            emit NewBid(tokenID: id, bidPrice: itemsRef.bidVault.balance)
        }

        // releasePreviousBid returns the outbid user's tokens to
        // their vault receiver
        pub fun releasePreviousBid(_ id: UInt64) {
            // get a reference to the auction items resources
            let auctionItem = &self.auctionItems[id] as &auctionItemResources
            // release the bidTokens from the vault back to the bidder
            auctionItem.releaseBidderTokens()
        }

        pub fun returnAuctionItemToOwner(_ id: UInt64) {
            let ownerCollectionRef = self.ownerNFTReceiverCap.borrow() ?? panic("Could not borrow ownerNFTRecipientCap")
            let auctionItem <- self.auctionItems.remove(key: id)!
            
            // release the bidder's tokens
            auctionItem.releaseBidderTokens()

            // withdraw the NFT from the auction collection
            let NFT <-auctionItem.withdrawNFT()
            
            // deposit the NFT into the owner's collection
            ownerCollectionRef.deposit(token:<-NFT)

            // destroy the leftover resource
            destroy auctionItem

            // clear the NFT's meta data
            self.auctionItemsMeta[id] = nil
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
    pub fun createAuctionCollection(
        ownerNFTCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
        ownerVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>,
    ): @AuctionCollection {

        let auctionCollection <- create AuctionCollection(
            ownerNFTReceiverCap: ownerNFTCollectionCapability,
            ownerVaultCapability: ownerVaultCapability
        )

        return <- auctionCollection
    }

    init() {}   
}
 