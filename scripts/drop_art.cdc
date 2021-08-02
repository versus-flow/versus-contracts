
import Versus from "../contracts/Versus.cdc"

pub fun main(dropID: UInt64) : String {

    return Versus.getArtForDrop(dropID)!
}
