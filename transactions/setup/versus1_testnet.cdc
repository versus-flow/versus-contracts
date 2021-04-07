

//local emulator
//import FungibleToken from 0xee82856bf20e2aa6
//import NonFungibleToken, Content, Art, Auction, Versus from 0x467694dd28ef0a12

//these are testnet 
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0x467694dd28ef0a12

//this transaction is run as the account that will host and own the marketplace to set up the 
//versusAdmin client and create the empty content and art collection
transaction() {

    prepare(account: AuthAccount) {

        //create empty Art collection
        account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)
        account.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)

        //create an Art admin client
        account.save(<- Art.createAdminClient(), to:Art.AdministratorStoragePath)
        account.link<&{Art.AdministratorClient}>(Art.AdministratorPublicPath, target: Art.AdministratorStoragePath)

        //create empty content collection
        account.save(<- Content.createEmptyCollection(), to: Content.CollectionStoragePath)
        account.link<&Content.Collection>(Content.CollectionPrivatePath, target: Content.CollectionStoragePath)

        //create versus admin client
        account.save(<- Versus.createAdminClient(), to:Versus.VersusAdminClientStoragePath)
        account.link<&{Versus.VersusAdminClient}>(Versus.VersusAdminClientPublicPath, target: Versus.VersusAdminClientStoragePath)


    }
}
