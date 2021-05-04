

//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

//these are testnet 
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0

//This transactions is run as the owner of the versus contract and links in the client
//ownerAddress is the address that will host the marketplace
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let versusAdminCap=account.getCapability<&Versus.DropCollection>(Versus.CollectionPrivatePath)
        client.addCapability(versusAdminCap)

      

    }
}
 