import AuctionDutch from "../contracts/AuctionDutch.cdc"

pub fun main(address: Address) : [AuctionDutch.ExcessFlowReport]   {
	let account=getAccount(address)
	let bidCollection=account.getCapability<&AuctionDutch.BidCollection{AuctionDutch.BidCollectionPublic}>(AuctionDutch.BidCollectionPublicPath).borrow()!
	var reports :[AuctionDutch.ExcessFlowReport] =[]
	for bid in bidCollection.getIds() {
		reports.append(bidCollection.getReport(bid))
	}
	return reports
}

