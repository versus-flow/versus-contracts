import Versus from "../contracts/Versus.cdc"
//check the status of a drop
pub fun main(dropID: UInt64) : Bool {

    let drop= Versus.getDrop(dropID)
	if drop == nil {
		return false
	}

    if drop?.active == false && drop?.settledAt == nil {
		return true
	}
	return false

}
