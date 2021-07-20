
import Versus from "../../contracts/Versus.cdc"

//fetch the drop status
pub fun main(dropID: UInt64) : Versus.DropStatus {

    return Versus.getDrop(dropID)!
}
