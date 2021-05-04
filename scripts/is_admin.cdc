
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Art from 0x1ff7e32d71183db0

//emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

/*
  This script will check an address and print out its an admin
 */
pub fun main(address:Address) : Bool {

    let account=getAccount(address)
    let adminClient: Capability<&{Versus.AdminPublic}> =account.getCapability<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath) 
    return adminClient.check()

}
