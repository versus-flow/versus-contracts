
//testnet
//import Art, Versus from 0xdb47998bf96c9ef1


//local emulator
import Art, Versus from 0xf8d6e0586b0a20c7


transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    content: String, 
    description: String) {

    let artistCollection: Capability<&{Art.CollectionPublic}>
    let client: &Versus.Admin

    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistCollection= getAccount(artist).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
    }

    execute {
        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:content, description: description)
        self.artistCollection.borrow()!.deposit(token: <- art)
    }
}

