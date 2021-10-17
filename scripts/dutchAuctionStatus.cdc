import AuctionDutch from "../contracts/AuctionDutch.cdc"
//check the status of a dutch auction
pub fun main(id: UInt64) : AuctionDutch.AuctionDutchStatus {
    return AuctionDutch.getAuctionDutch(id)!
}
