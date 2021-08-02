import Art from "../contracts/Art.cdc"

/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(bidder:Address) : Bool {
   
    return getAccount(bidder).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath).check()
}
 
 
 
