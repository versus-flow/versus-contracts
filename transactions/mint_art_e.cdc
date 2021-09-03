import Versus from "../contracts/Versus.cdc"
import Art from "../contracts/Art.cdc"

//Transaction to mint Art and edition art and deploy to all addresses
transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    description: String,
    addresses: [Address]) {

    let client: &Versus.Admin
    let content: String

    prepare(account: AuthAccount) {

        let path = /storage/upload
        self.content= account.load<String>(from: path) ?? panic("could not load content")
        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
    }

    execute {
        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:self.content, description: description)
        self.client.editionAndDepositArt(art: &art as &Art.NFT, to: addresses)
        destroy art
    }
}

