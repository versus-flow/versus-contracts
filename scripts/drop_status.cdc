import Versus from "./contracts/Versus.cdc"
//check the status of a drop
pub fun main(dropID: UInt64) : Versus.DropStatus {

    return Versus.getDrop(dropID)!
}
