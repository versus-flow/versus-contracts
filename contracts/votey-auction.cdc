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

    pub struct AuctionQueueMeta {
        pub(set) var votes: UInt64
        pub(set) var startPrice: UFix64

        init(votes: UInt64, startPrice: UFix64) {
            self.votes = votes
            self.startPrice = startPrice
        }
    }

    pub resource interface AuctionPublic {
        pub fun getAuctionQueuePrices(): {UInt64: UFix64}
    }

    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionQueue: @{UInt64: NonFungibleToken.NFT}
        pub var currentAuctionItem: @NonFungibleToken.NFT?

        // Current Price
        pub var currentAuctionPrice: UFix64
        pub var currentAuctionStartPrice: UFix64

        // Auction Queue Meta Data
        pub var auctionQueueMeta: {UInt64: AuctionQueueMeta}

        // Auction Settings
        pub let minimumBidIncrement: UFix64
        pub let auctionLengthInBlocks: UInt64
        pub var auctionStartBlock: UInt64

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
            self.currentAuctionItem <- nil
            self.currentAuctionPrice = UFix64(0)
            self.currentAuctionStartPrice = UFix64(0)
            self.auctionQueueMeta = {}
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.auctionStartBlock = UInt64(0)
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
            //self.auctionQueuePrices[tokenID] = newPrice
            self.auctionQueueMeta[tokenID]!.startPrice = newPrice
            emit TokenStartPriceUpdated(tokenID: tokenID, newPrice: newPrice)
        }

        // getAuctionQueuePrices 
        pub fun getAuctionQueuePrices(): {UInt64: UFix64} {
            let priceList: {UInt64: UFix64} = {}

            for id in self.auctionQueueMeta.keys {
                priceList[id] = self.auctionQueueMeta[id]!.startPrice
            }
            
            return priceList
        }

        // startAuction removes the token with the highest ID number from the
        // auction queue and puts it up for auction while storing the current block number
        pub fun startAuction() {
            pre {
                self.currentAuctionItem.length == 0:
                "the auction has already been started"
            }
            // Store the current block height as the start block number
            let currentBlock = getCurrentBlock()
            self.auctionStartBlock = currentBlock.height

            // update the current auction item from the auction queue
            self.updateCurrentAuctionItem()
        }

        // updateCurrentAuctionItem adds the next token from the auction queue
        // to the current auction array
        access(contract) fun updateCurrentAuctionItem() {
            pre {
                self.auctionQueue.keys.length > 0:
                "there are no tokens in the auction queue"
            }
            
            // get the next token ID
            var tokenID = self.getNextTokenID()

            // update the auction start price
            if let queueItem = self.auctionQueueMeta[tokenID] {
                self.currentAuctionPrice = queueItem.startPrice
                self.currentAuctionStartPrice = queueItem.startPrice
            }

            // remove the next token from the auction queue
            if let token <- self.getTokenFromAuctionQueue(tokenID: tokenID) {
                // append the token to the currentAuctionItem array
                self.currentAuctionItem.append(<-token)
            } else {
                // end the auction
                log("no more tokens in the auction queue")
            }            
        }

        // getNextTokenID() returns the token ID with the highest vote count, if any.
        // Otherwise it returns the tokenID with the highest ID number
        pub fun getNextTokenID(): UInt64 {
            var tokenID = self.getHighestVoteCountID()

            if tokenID == nil {
                tokenID = self.getHighestTokenID()
            }

            return tokenID!
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

        // getTokenFromAuctionQueue removes the token from the auction queue
        // and returns it to the caller
        pub fun getTokenFromAuctionQueue(tokenID: UInt64): @NonFungibleToken.NFT? {

            self.auctionQueueMeta[tokenID] = nil

            // withdraw the token and return it to the caller
            let nextToken <- self.auctionQueue.remove(key: tokenID)
            return <-nextToken
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
            //
            if self.currentAuctionItem != nil {           
                // If there were no bids...
                if self.currentAuctionPrice == self.currentAuctionStartPrice {
                    //... send the token back into the auction queue
                    let id = self.currentAuctionItem?.id;
                    
                    self.auctionQueue[id!] <-> self.currentAuctionItem

                    /* 
                    if let existingToken <- self.auctionQueue.remove(key: id!){
                        // let oldToken <- existingToken <- self.currentAuctionItem
                         self.auctionQueue[id] <- self.currentAuctionItem
                        destroy existingToken
                    }
                    */
                } else {
                    //... send the token to the highest bidder
                    destroy self.currentAuctionItem
                }

            } else {
                log("there is no auction to settle")
            }
        }

        destroy() {
            destroy self.auctionQueue
            destroy self.currentAuctionItem
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
 