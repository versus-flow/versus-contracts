import DutchAuction from "../contracts/DutchAuction.cdc"
//check the status of a dutch auction
pub fun main(id: UInt64) : [DutchAuction.BidReport]{
    return DutchAuction.getBids(id)
}
