// This transaction starts the auction in storage on account 1

// Signer - Account 1 - 0x01cf0e2f2f715450

import VoteyAuction from 0xe03daebed8ca0615

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

transaction{
    prepare(account: AuthAccount) {

        let auction = account.borrow<&VoteyAuction.AuctionCollection>(from: /storage/NFTAuction)
            ?? panic("Couldn't borrow a reference to the Auction Collection")

        auction.startAuction()
    }
}