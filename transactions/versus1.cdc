import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Content from "../contracts/Content.cdc"
import Art from "../contracts/Art.cdc"
import Versus from "../contracts/Versus.cdc"
import Auction from "../contracts/Auction.cdc"

//this transaction is run as the account that will host and own the marketplace to set up the 
//versusAdmin client and create the empty content and art collection
transaction() {

	prepare(account: AuthAccount) {


		if account.getCapability(Versus.VersusAdminPublicPath).check<&AnyResource>() {
			account.unlink(Versus.VersusAdminPublicPath)
			destroy <- account.load<@AnyResource>(from: Versus.VersusAdminStoragePath)
		}
		//create versus admin client
		account.save(<- Versus.createAdminClient(), to:Versus.VersusAdminStoragePath)
		account.link<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath, target: Versus.VersusAdminStoragePath)


	}
}
