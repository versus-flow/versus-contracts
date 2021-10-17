import AuctionDutch from "../contracts/AuctionDutch.cdc"

// Transaction to cancel a dutch auction bid
transaction(id: UInt64) {

	let dutchAuction: &AuctionDutch.BidCollection

	prepare(account: AuthAccount) {

		self.dutchAuction=account.borrow<&AuctionDutch.BidCollection>(from: AuctionDutch.BidCollectionStoragePath) ?? panic("Could not borrow bid collection")
	}

	execute {
		self.dutchAuction.cancelBid(id)
	}

	post {
		!self.dutchAuction.getIds().contains(id) : "Should not contain bid"
	}
}

