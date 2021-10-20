import DutchAuction from "../contracts/DutchAuction.cdc"

pub fun main(address: Address) : [DutchAuction.ExcessFlowReport]   {
	let account=getAccount(address)
	let bidCollection=account.getCapability<&DutchAuction.BidCollection{DutchAuction.BidCollectionPublic}>(DutchAuction.BidCollectionPublicPath).borrow()!
	var reports :[DutchAuction.ExcessFlowReport] =[]
	for bid in bidCollection.getIds() {
		reports.append(bidCollection.getReport(bid))
	}
	return reports
}

