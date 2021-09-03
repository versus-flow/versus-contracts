
import Versus from "../contracts/Versus.cdc"
import Art from "../contracts/Art.cdc"

//mint an art and add it to a users collection
transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    description: String,
	  target:Address) {

    let artistCollection: Capability<&{Art.CollectionPublic}>
    let client: &Versus.Admin
		let content: String

    prepare(account: AuthAccount) {
        let path = /storage/upload
        self.content= account.load<String>(from: path) ?? panic("could not load content")
 
        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistCollection= getAccount(target).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
    }

    execute {
        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:self.content, description: description)
        self.artistCollection.borrow()!.deposit(token: <- art)
    }
}

