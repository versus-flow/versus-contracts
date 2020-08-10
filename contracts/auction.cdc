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
    pub event TokenAddedToAuctionQueue(tokenID: UInt64, startPrice: UFix64)
    pub event TokenStartPriceUpdated(tokenID: UInt64, newPrice: UFix64)
    pub event NewBid(tokenID: UInt64, bidPrice: UFix64)
    pub event TokenPurchased(tokenID: UInt64, price: UFix64)
    pub event NewTokenAvailableForAuction(tokenID: UInt64, startPrice: UFix64)

    pub struct AuctionQueueMeta {
        pub(set) var votes: UInt64
        pub(set) var startPrice: UFix64
        pub(set) var currentPrice: UFix64

        init(votes: UInt64, startPrice: UFix64) {
            self.votes = votes
            self.startPrice = startPrice
            self.currentPrice = startPrice
        }
    }

    pub resource interface AuctionPublic {
        pub fun getAuctionQueuePrices(): {UInt64: UFix64}
        pub fun placeBid(
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&AnyResource{FungibleToken.Receiver}>, 
            collectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        )
    }

    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionQueue: @{UInt64: NonFungibleToken.NFT}
        pub var auctionQueueMeta: {UInt64: AuctionQueueMeta}
        pub var currentAuctionItemID: UInt64?

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
            self.auctionQueue <- {}
            self.currentAuctionItemID = nil
            self.auctionQueueMeta = {}
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.auctionStartBlock = UInt64(0)
            self.recipientNFTCollectionCapability = nil
            self.recipientVaultCapability = nil
            self.ownerNFTCollectionCapability = ownerNFTCollectionCapability
            self.ownerVaultCapability = ownerVaultCapability
            self.bidVault <- bidVault
        }

        // addTokenToAuctionQueue adds a token to the auction queue, sets the start price
        // and sets the vote count to 0
        pub fun addTokenToAuctionQueue(token: @NonFungibleToken.NFT, startPrice: UFix64) {
            // store the token ID
            let tokenID = token.id

            // set the initial vote count to 0
            self.auctionQueueMeta[tokenID] = AuctionQueueMeta(votes: UInt64(0), startPrice: startPrice)

            // add the token to the auction queue
            let oldToken <- self.auctionQueue[tokenID] <- token
            destroy oldToken

            emit TokenAddedToAuctionQueue(tokenID: tokenID, startPrice: startPrice)
        }

        // changeStartPrice updates the start price value for an NFT in the auction queue
        pub fun changeStartPrice(tokenID: UInt64, newPrice: UFix64) {
            
            // update both the startPrice and currentPrice as we'll compare
            // these to determine whether there were any bids
            self.auctionQueueMeta[tokenID]!.startPrice = newPrice
            self.auctionQueueMeta[tokenID]!.currentPrice = newPrice

            emit TokenStartPriceUpdated(tokenID: tokenID, newPrice: newPrice)
        }

        // getAuctionQueuePrices 
        pub fun getAuctionQueuePrices(): {UInt64: UFix64} {
            let priceList: {UInt64: UFix64} = {}

            for id in self.auctionQueueMeta.keys {
                priceList[id] = self.auctionQueueMeta[id]!.currentPrice
            }
            
            return priceList
        }

        // startAuction removes the token with the highest ID number from the
        // auction queue and puts it up for auction while storing the current block number
        pub fun startAuction() {
            pre {
                self.currentAuctionItemID == nil:
                    "the auction is already in progress"
            }

            // update the current auction item from the auction queue
            self.updateCurrentAuctionItemID()
        }

        // updateCurrentAuctionItemID adds the next token from the auction queue
        // to the current auction array
        pub fun updateCurrentAuctionItemID() {
            pre {
                self.auctionQueue.keys.length > 0:
                    "there are no tokens in the auction queue"
            }
            
            // get the next token ID
            var tokenID = self.getNextTokenID()
            
            // set the current auction item to the new token ID
            self.currentAuctionItemID = tokenID

            // set the auction start block to the current block height
            let currentBlock = getCurrentBlock()
            self.auctionStartBlock = currentBlock.height

            emit NewTokenAvailableForAuction(tokenID: tokenID, startPrice: self.auctionQueueMeta[tokenID]!.startPrice)
        }

        // getNextTokenID() returns the token ID with the highest vote count, if any.
        // Otherwise it returns the tokenID with the highest ID number
        pub fun getNextTokenID(): UInt64 {
            if let highestVoteTokenID = self.getHighestVoteCountID() {
                return highestVoteTokenID
            } else {
                return self.getHighestTokenID()
            }
        }

        // getHighestVoteCountID returns the id for the token with the
        // highest vote count, or nil if all votes equal zero
        pub fun getHighestVoteCountID(): UInt64? {
            let keys = self.auctionQueueMeta.keys

            if keys.length == 0 { return nil }

            var tokenID: UInt64? = nil
            var highestCount: UInt64 = 0
            var counter: UInt64 = 0

            // while there are still tokens to loop through...
            while counter < UInt64(keys.length) {
                // get the vote count for the current token in the auction queue
                if let queueItem = self.auctionQueueMeta[self.auctionQueue.keys[counter]] {
                    // ... if the vote count is higher than the current highest count...
                    if highestCount < queueItem.votes {
                        // ... update the current highest count for the next iteration
                        highestCount = queueItem.votes
                        // ... set the token ID to the current token
                        tokenID = self.auctionQueue.keys[counter]
                    }
                } else {
                    log("auction queue is out of sync?")
                }
            }
            return tokenID
        }

        // getHighestTokenID returns the highest token ID in the auction queue
        pub fun getHighestTokenID(): UInt64 {
            // set the initial tokenID to zero
            var tokenID: UInt64 = 0

            // for each token ID in the auction queue...
            for id in self.auctionQueue.keys {
                if id > tokenID {
                    tokenID = id
                }
            }

            return tokenID
        }

        // maybeUpdateAuctionItem updates the current auction item if the current
        // auction has expired
        pub fun maybeUpdateAuctionItem() {
            let currentBlock = getCurrentBlock()
            let blockTimeDifference = currentBlock.height - self.auctionStartBlock

            if blockTimeDifference >= self.auctionLengthInBlocks {
                self.settleCurrentAuction()
                self.updateCurrentAuctionItemID()
            }
            
        }

        // settleCurrentAuction sends the current auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleCurrentAuction() {
            pre {
                self.recipientNFTCollectionCapability != nil:
                    "Recipient's NFT receiver capability is invalid"
            }
            // If there is a token available for auction
            if let tokenID = self.currentAuctionItemID {
                
                // get the token meta data
                let tokenMeta = self.auctionQueueMeta[tokenID]??
                    panic("no meta data for current auction item. we broken!")
                
                // If there were bids...
                if tokenMeta.currentPrice != tokenMeta.startPrice {

                    if let purchasedToken <- self.auctionQueue.remove(key: tokenID) {
                        
                        //... borrow a reference to the highest bidder's NFT collection receiver
                        let recipientNFTCollectionRef = self.recipientNFTCollectionCapability!.borrow()
                        
                        //... send the NFT to the highest bidder
                        recipientNFTCollectionRef!.deposit(token: <-purchasedToken)
                        
                        //... borrow a reference to the owner's Vault
                        let ownerVaultRef = self.ownerVaultCapability.borrow()

                        //... send the FTs to the Auction Owner
                        let bidVaultTokens <- self.bidVault.withdraw(amount: self.bidVault.balance)
                        ownerVaultRef!.deposit(from:<-bidVaultTokens)

                        emit TokenPurchased(tokenID: tokenID, price: tokenMeta.currentPrice)

                    } else {
                        log("user purchased a token that doesn't exist.")
                    }

                } else {
                    log("there were no bids for the auction.")
                }

            } else {
                log("there is no auction to settle. [BAD]")
            }
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&AnyResource{FungibleToken.Receiver}>, 
            collectionCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        ) 
            {
            pre {
                self.currentAuctionItemID != nil:
                    "there is no item to bid on"
                bidTokens.balance - self.auctionQueueMeta[self.currentAuctionItemID!]!.currentPrice >= self.minimumBidIncrement:
                    "bid amount must be larger than the minimum bid increment"
                vaultCap != nil:
                    "Bidder's Vault receiver capability is invalid"
                collectionCap != nil:
                    "Bidder's NFT Collection capability is invalid"
            }

            // get the meta data for the current token
            let tokenID = self.currentAuctionItemID!
            let currentTokenMeta = self.auctionQueueMeta[tokenID]!

            // release any previously held bid tokens
            self.releasePreviousBid()

            // Store the new bidder's tokens
            self.bidVault.deposit(from:<-bidTokens)

            // Update the current price of the token
            currentTokenMeta.currentPrice = self.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            self.recipientVaultCapability = vaultCap
            self.recipientNFTCollectionCapability = collectionCap

            // check if the auction needs to be updated
            self.maybeUpdateAuctionItem()

            emit NewBid(tokenID: tokenID, bidPrice: currentTokenMeta.currentPrice)
        }

        // releasePreviousBid returns the outbid user's tokens to
        // their vault receiver
        pub fun releasePreviousBid() {
            // If there was a previous bidder...
            if var recipientVaultCapability = self.recipientVaultCapability {
                //... send the previous bidder's tokens back
                let oldBalance <- self.bidVault.withdraw(amount: self.bidVault.balance)
                
                //... borrow a reference to the recipient's Vault receiver
                let recipientVaultRef = self.recipientVaultCapability!.borrow()

                //.. deposit the tokens in the recipient's Vault
                recipientVaultRef!.deposit(from:<-oldBalance)
            }
        }

        pub fun returnAuctionQueueItemsToOwner() {

            // borrow a reference to the auction owner's NFT Collection
            let ownerCollectionRef = self.ownerNFTCollectionCapability.borrow()

            // get the IDs from the auction queue
            let auctionQueueIDs = self.auctionQueue.keys

            // for each ID in the auction queue...
            for id in auctionQueueIDs {
                // ... remove the NFT from the auction queue and deposit it into
                // the owner's collection
                ownerCollectionRef!.deposit(token:<-self.auctionQueue.remove(key: id)!)
                
                // ... clear the NFT's meta data from the auction queue
                self.auctionQueueMeta[id] = nil
            }
        }

        destroy() {
            // return all NFTs in the auctionQueue to the resource owner
            self.returnAuctionQueueItemsToOwner()

            // return bidToken balance to the bidder
            self.releasePreviousBid()

            // destroy the empty resources
            destroy self.auctionQueue
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
 