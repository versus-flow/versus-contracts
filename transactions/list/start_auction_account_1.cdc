// This transaction starts the auction in storage on account 1

// Signer - Account 1 - 0x01cf0e2f2f715450

import VoteyAuction from 0xf3fcd2c1a78f5eee

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - demo-token.cdc
// Acct 2 - 0x179b6b1cb6755e31 - rocks.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - votey-auction.cdc
// Acct 4 - 0xe03daebed8ca0615 - onflow/NonFungibleToken.cdc

transaction{
    prepare(account: AuthAccount) {

        let auction = account.borrow<&VoteyAuction.AuctionCollection>(from: /storage/NFTAuction)
            ?? panic("Couldn't borrow a reference to the auction collection stored in account 1")

        auction.startAuction()
    }
}