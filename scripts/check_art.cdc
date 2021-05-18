// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Art from 0x1ff7e32d71183db0


//mainnnet
import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import Content, Art, Auction, Versus from  0xd796ff17107bbff6

/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(bidder:Address) : Bool {
   
    return getAccount(bidder).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath).check()
}
 
 
 
