import DutchAuction from "../contracts/DutchAuction.cdc"
//check the status of a dutch auction
pub fun main(id: UInt64) : DutchAuction.Bids {
    return DutchAuction.getBids(id)
}
