import AuctionDutch from "../contracts/AuctionDutch.cdc"
//check the status of a dutch auction
pub fun main(address: Address) : [UInt64] {

	let account=getAccount(address)
	let bidCap=account.getCapability<&AuctionDutch.BidCollection{AuctionDutch.BidCollectionPublic}>(AuctionDutch.BidCollectionPublicPath)
	return bidCap.borrow()!.getIds()
}
