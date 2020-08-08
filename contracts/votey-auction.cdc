// VoteyAuction.cdc
//
// The VoteyAuction contract is an experimental implementation of an NFT Auction on Flow.
//
// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.
//
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xe03daebed8ca0615

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - demo-token.cdc
// Acct 2 - 0x179b6b1cb6755e31 - rocks.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - votey-auction.cdc
// Acct 4 - 0xe03daebed8ca0615 - onflow/NonFungibleToken.cdc
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
        // TODO: Add all public methods here
        pub fun getAuctionQueuePrices(): {UInt64: UFix64}
    }

    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionQueue: @{UInt64: NonFungibleToken.NFT}
        pub var auctionQueueMeta: {UInt64: AuctionQueueMeta}
        pub var currentAuctionItem: UInt64?

        // Auction Settings
        pub let minimumBidIncrement: UFix64
        pub let auctionLengthInBlocks: UInt64
        pub var auctionStartBlock: UInt64

        // Recipient's Receiver References
        pub var recipientNFTCollection: &AnyResource{NonFungibleToken.CollectionPublic}?
        pub var recipientVault: &AnyResource{FungibleToken.Receiver}?

        // Vaults
        pub let ownerVault: &AnyResource{FungibleToken.Receiver}
        pub let bidVault: @FungibleToken.Vault


        init(
            minimumBidIncrement: UFix64,
            auctionLengthInBlocks: UInt64,
            ownerVault: &AnyResource{FungibleToken.Receiver},
            bidVault: @FungibleToken.Vault
        ) {
            self.auctionQueue <- {}
            self.currentAuctionItem = nil
            self.auctionQueueMeta = {}
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.auctionStartBlock = UInt64(0)
            self.recipientNFTCollection = nil
            self.recipientVault = nil
            self.ownerVault = ownerVault
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
                self.currentAuctionItem == nil:
                "the auction has already been started"
            }
            // Store the current block height as the start block number
            let currentBlock = getCurrentBlock()
            self.auctionStartBlock = currentBlock.height

            log("got the current block height")

            // update the current auction item from the auction queue
            self.updateCurrentAuctionItem()
        }

        // updateCurrentAuctionItem adds the next token from the auction queue
        // to the current auction array
        pub fun updateCurrentAuctionItem() {
            pre {
                self.auctionQueue.keys.length > 0:
                "there are no tokens in the auction queue"
            }

            log("CODE BREAKS IN UPDATE FUNCTION")
            
            // get the next token ID
            var tokenID = self.getNextTokenID()
            
            // set the current auction item to the new token ID
            self.currentAuctionItem = tokenID

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
                self.updateCurrentAuctionItem()
            }
            
        }

        // settleCurrentAuction sends the current auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleCurrentAuction() {
            
            // If there is a token available for auction
            if let tokenID = self.currentAuctionItem {
                
                // get the token meta data
                let tokenMeta = self.auctionQueueMeta[tokenID]??
                    panic("no meta data for current auction item. we broken!")
                
                // If there were bids...
                if tokenMeta.currentPrice != tokenMeta.startPrice {

                    if let purchasedToken <- self.auctionQueue.remove(key: tokenID) {
                        
                        //... send the NFT to the highest bidder
                        self.recipientNFTCollection!.deposit(token: <-purchasedToken)
                        
                        //... send the FTs to the Auction Owner
                        let bidVaultTokens <- self.bidVault.withdraw(amount: self.bidVault.balance)
                        self.ownerVault.deposit(from:<-bidVaultTokens)

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
            vaultRef: &AnyResource{FungibleToken.Receiver}, 
            collectionRef: &AnyResource{NonFungibleToken.CollectionPublic}) 
            {
            pre {
                self.currentAuctionItem != nil:
                "there is no item to bid on"
                bidTokens.balance - self.auctionQueueMeta[self.currentAuctionItem!]!.currentPrice >= self.minimumBidIncrement:
                "bid amount must be larger than the minimum bid increment"
            }

            // get the meta data for the current token
            let tokenID = self.currentAuctionItem!
            let currentTokenMeta = self.auctionQueueMeta[tokenID]!

            // release any previously held bid tokens
            self.releasePreviousBid()

            // Store the new bidder's tokens
            self.bidVault.deposit(from:<-bidTokens)

            // Update the current price of the token
            currentTokenMeta.currentPrice = self.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            self.recipientVault = vaultRef
            self.recipientNFTCollection = collectionRef

            // check if the auction needs to be updated
            self.maybeUpdateAuctionItem()

            emit NewBid(tokenID: tokenID, bidPrice: currentTokenMeta.currentPrice)
        }

        // releasePreviousBid returns the outbid user's tokens to
        // their vault receiver
        access(contract) fun releasePreviousBid() {
            // If there was a previous bidder...
            if var recipientVault = self.recipientVault {
                //... send the previous bidder's tokens back
                let oldBalance <- self.bidVault.withdraw(amount: self.bidVault.balance)
                recipientVault.deposit(from:<-oldBalance)
            }
        }

        destroy() {
            destroy self.auctionQueue
            destroy self.bidVault
        }
    }

    // createAuctionCollection returns a new AuctionCollection resource to the caller
    pub fun createAuctionCollection(
        minimumBidIncrement: UFix64,
        auctionLengthInBlocks: UInt64,
        ownerVault: &AnyResource{FungibleToken.Receiver},
        bidVault: @FungibleToken.Vault
    ): @AuctionCollection {

        let auctionCollection <- create AuctionCollection(
            minimumBidIncrement: minimumBidIncrement,
            auctionLengthInBlocks: auctionLengthInBlocks,
            ownerVault: ownerVault,
            bidVault: <-bidVault
        )

        emit NewAuctionCollectionCreated(minimumBidIncrement: minimumBidIncrement, auctionLengthInBlocks: auctionLengthInBlocks)

        return <- auctionCollection
    }

    init() {
        log("Auction contract deployed")
    }   
}
 