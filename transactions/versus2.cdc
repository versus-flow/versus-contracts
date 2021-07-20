

import Versus from "../../contracts/Versus.cdc"

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
 
