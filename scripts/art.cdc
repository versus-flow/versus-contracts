import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Art from "../contracts/Art.cdc"

pub fun main(address:Address) : [UInt64] {
	let account=getAccount(address)
	let artCollection= account.getCapability(Art.CollectionPublicPath).borrow<&{Art.CollectionPublic}>()!
	return artCollection.getIDs()
}
