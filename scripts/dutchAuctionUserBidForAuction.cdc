import DutchAuction from "../contracts/DutchAuction.cdc"

pub fun main(address: Address, auction: UInt64) : [DutchAuction.ExcessFlowReport]   {
	let account=getAccount(address)
	let bidCollection=account.getCapability<&DutchAuction.BidCollection{DutchAuction.BidCollectionPublic}>(DutchAuction.BidCollectionPublicPath).borrow()!
	var reports :[DutchAuction.ExcessFlowReport] =[]
	for bid in bidCollection.getIds() {
		let report=bidCollection.getReport(bid)
		if report.auctionId==auction {
			reports.append(bidCollection.getReport(bid))
		}
	}
	return reports
}

