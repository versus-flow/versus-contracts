// This transaction creates a new Auction Collection object,
// lists all NFTs for auction, puts it in account storage,
// and creates a public capability to the auction so that 
// others can bid on the tokens.

// Signer - Account 1 - 0x01cf0e2f2f715450

import NonFungibleToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31
import VoteyAuction from 0xe03daebed8ca0615

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

transaction {
    prepare(account: AuthAccount) {
        let bidVault <- DemoToken.createEmptyVault()

        // get the public Capability for the signer's Vault
        let receiver = account.getCapability<&DemoToken.Vault{FungibleToken.Receiver}>(/public/DemoTokenVault)??
            panic("Account 1 has no DemoToken Vault capability")

        // borrow a reference to the entire NFT Collection functionality (for withdrawing)
        let accountCollectionRef = account.borrow<&NonFungibleToken.Collection>(from: /storage/RockCollection)!

        // get the public Capability for the signer's NFT collection (for the auction)
        let publicCollectionCap = account.getCapability<&NonFungibleToken.Collection{NonFungibleToken.CollectionPublic}>(/public/RockCollection)
        ?? panic("Unable to borrow a reference to the NFT collection")

        // create a new sale object     
        // initializing it with the reference to the owner's Vault
        let auction <- VoteyAuction.createAuctionCollection(
            minimumBidIncrement: UFix64(5),
            auctionLengthInBlocks: UInt64(30),
            ownerNFTCollectionCapability: publicCollectionCap,
            ownerVaultCapability: receiver,
            bidVault: <-bidVault
        )

        let collectionIDs = accountCollectionRef.getIDs()

        for id in collectionIDs {
            // withdraw the NFT from the collection that you want to sell
            // and move it into the transaction's context
            let NFT <- accountCollectionRef.withdraw(withdrawID: id)

            // list the token for sale by moving it into the sale resource
            auction.addTokenToAuctionQueue(token: <-NFT, startPrice: UFix64(10))
        }

        // store the sale resource in the account for storage
        account.save(<-auction, to: /storage/NFTAuction)

        // create a public capability to the sale so that others
        // can call it's methods
        account.link<&VoteyAuction.AuctionCollection{VoteyAuction.AuctionPublic}>(
            /public/NFTAuction,
            target: /storage/NFTAuction
        )

        log("Auction created for account 1. Listed NFT ids[1-10] for start price of 10 DemoTokens each.")
    }
}
 