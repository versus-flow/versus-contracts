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

    pub resource interface AuctionPublic {
        pub fun getAuctionQueuePrices(): {UInt64: UFix64}
    }

    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionQueue: @{UInt64: NonFungibleToken.NFT}
        pub var currentAuctionItem: @[NonFungibleToken.NFT]

        // Auction Queue Meta Data
        pub var auctionQueuePrices: {UInt64: UFix64}
        pub var auctionQueueVotes: {UInt64: UInt64}

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
            ownerNFTCollection: &AnyResource{NonFungibleToken.CollectionPublic},
            bidVault: @FungibleToken.Vault
        ) {
            self.auctionQueue <- {}
            self.currentAuctionItem <- []
            self.auctionQueuePrices = {}
            self.auctionQueueVotes = {}
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

            // update the auction queue prices dictionary
            self.changeStartPrice(tokenID: tokenID, newPrice: startPrice)

            // set the initial vote count to 0
            self.auctionQueueVotes[tokenID] = UInt64(0)

            // add the token to the auction queue
            let oldToken <- self.auctionQueue[tokenID] <- token
            destroy oldToken


            emit TokenAddedToAuctionQueue(tokenID: tokenID, startPrice: startPrice)
        }

        // changeStartPrice updates the start price value for an NFT in the auction queue
        pub fun changeStartPrice(tokenID: UInt64, newPrice: UFix64) {
            self.auctionQueuePrices[tokenID] = newPrice

            emit TokenStartPriceUpdated(tokenID: tokenID, newPrice: newPrice)
        }

        // getAuctionQueuePrices 
        pub fun getAuctionQueuePrices(): {UInt64: UFix64} {
            return self.auctionQueuePrices
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
        ownerNFTCollection: &AnyResource{NonFungibleToken.CollectionPublic},
        bidVault: @FungibleToken.Vault
    ): @AuctionCollection {

        let auctionCollection <- create AuctionCollection(
            minimumBidIncrement: minimumBidIncrement,
            auctionLengthInBlocks: auctionLengthInBlocks,
            ownerVault: ownerVault,
            ownerNFTCollection: ownerNFTCollection,
            bidVault: <-bidVault
        )

        emit NewAuctionCollectionCreated(minimumBidIncrement: minimumBidIncrement, auctionLengthInBlocks: auctionLengthInBlocks)

        return <- auctionCollection
    }

    init() {
        log("Auction contract deployed")
    }
    
}
 