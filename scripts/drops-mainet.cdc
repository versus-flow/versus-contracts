
import Versus from 0xd796ff17107bbff6

/*
  Script used to get the first active drop in a versus 
 */
pub fun main() : [Versus.DropStatus] {

    return Versus.getDrops()
}
