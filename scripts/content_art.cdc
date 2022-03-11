import Art from "../contracts/Art.cdc"

pub fun main(address:Address, id: UInt64) : String? {
	return Art.getContentForArt(address: address, artId: id)
}
