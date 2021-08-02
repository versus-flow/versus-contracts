
import Versus from "../contracts/Versus.cdc"

/*
  Script used to get the first active drop in a versus 
 */
pub fun main() : [Versus.DropStatus] {

    return Versus.getDrops()
}
