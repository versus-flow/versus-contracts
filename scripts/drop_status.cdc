
import Versus from 0xd796ff17107bbff6

pub fun main(dropID: UInt64) : Versus.DropStatus {

    return Versus.getDrop(dropID)!
}