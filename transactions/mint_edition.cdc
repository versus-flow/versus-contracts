import NonFungibleToken from "../../contracts/standard/NonFungibleToken.cdc"
import Art from "../../contracts/Art.cdc"
import Versus from "../../contracts/Versus.cdc"

//transaction to create an edition of an nft in admins collection and send it to a user
transaction(
    user: Address,
    original:Address,
    artId: UInt64,
    edition: UInt64,
    maxEdition: UInt64) {

    let client: &Versus.Admin
    let nftCollection: &NonFungibleToken.Collection
    prepare(account: AuthAccount) {
        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.nftCollection =account.borrow<&NonFungibleToken.Collection>(from: Art.CollectionStoragePath)!
    }

    execute {

          let art <- self.nftCollection.withdraw(withdrawID: artId) as! @Art.NFT
          let newArt <- self.client.editionArt(art: &art as &Art.NFT, edition:edition, maxEdition:maxEdition)

          let userCollection : &{Art.CollectionPublic} = getAccount(user).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath).borrow()!
          userCollection.deposit(token: <- newArt)

          let originalCollection : &{Art.CollectionPublic} = getAccount(original).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath).borrow()!
          originalCollection.deposit(token: <- art)
    }
}

