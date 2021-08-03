import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Art from "../contracts/Art.cdc"



/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(address:Address) : { String: String}{
    // get the accounts' public address objects
    let account = getAccount(address)
    let art= Art.getArt(address: address)

	let dict : { String: String} = {}
	for a in art {
		dict[a.cacheKey] = a.metadata.name.concat("-").concat(a.metadata.artist)
	}
    
    return dict

}
