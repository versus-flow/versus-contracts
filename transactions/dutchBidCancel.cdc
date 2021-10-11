import DutchAuction from "../contracts/DutchAuction.cdc"

// Transaction to cancel a dutch auction bid
transaction(id: UInt64) {

	let dutchAuction: &DutchAuction.BidCollection

	prepare(account: AuthAccount) {

		self.dutchAuction=account.borrow<&DutchAuction.BidCollection>(from: DutchAuction.BidCollectionStoragePath) ?? panic("Could not borrow bid collection")
	}

	execute {
		self.dutchAuction.cancelBid(id)
	}

	post {
		!self.dutchAuction.getIds().contains(id) : "Should not contain bid"
	}
}

