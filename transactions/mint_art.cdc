
import Versus from "../contracts/Versus.cdc"
import Art from "../contracts/Art.cdc"

//mint an art and add it to a users collection
transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    content: String, 
    description: String, 
    type: String, 
    artistCut: UFix64, 
    minterCut: UFix64,
    receiverPath: PublicPath
    ) {

    let artistCollection: Capability<&{Art.CollectionPublic}>
    let client: &Versus.Admin

    prepare(account: AuthAccount) {

      self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistCollection= getAccount(artist).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
    }

  execute {
      let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:content, description: description, type:type, artistCut: artistCut, minterCut:minterCut, receiverPath: receiverPath)
      self.artistCollection.borrow()!.deposit(token: <- art)
  }
}

