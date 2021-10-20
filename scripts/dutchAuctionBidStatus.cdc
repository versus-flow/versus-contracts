import DutchAuction from "../contracts/DutchAuction.cdc"
//check the status of a dutch auction
pub fun main(address: Address) : [UInt64] {
	let account=getAccount(address)
	let bidCap=account.getCapability<&DutchAuction.BidCollection{DutchAuction.BidCollectionPublic}>(DutchAuction.BidCollectionPublicPath)
	return bidCap.borrow()!.getIds()
}
