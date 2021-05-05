import NonFungibleToken from 0x1d7e57aa55817448
import Art, Versus from 0xd796ff17107bbff6

transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    description: String) {

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

