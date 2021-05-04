
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus from 0xd796ff17107bbff6


//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import Art, Versus from 0xf8d6e0586b0a20c7

transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    content: String, 
    description: String) {

    let artistCollection: Capability<&{Art.CollectionPublic}>
    let client: &Versus.Admin
    let addresses: [Address]

    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistCollection= getAccount(artist).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
        self.addresses=[artist, artist]
    }

    execute {
        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:content, description: description)
        self.client.editionAndDepositArt(art: <- art, to: self.addresses)
    }
}

