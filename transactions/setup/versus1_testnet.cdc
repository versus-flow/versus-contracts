

//these are testnet 
import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import Content, Art, Auction, Versus from 0xd796ff17107bbff6

//this transaction is run as the account that will host and own the marketplace to set up the 
//versusAdmin client and create the empty content and art collection
transaction() {

    prepare(account: AuthAccount) {

        //create versus admin client
        account.save(<- Versus.createAdminClient(), to:Versus.VersusAdminStoragePath)
        account.link<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath, target: Versus.VersusAdminStoragePath)


    }
}
