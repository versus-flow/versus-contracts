
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus from 0xd796ff17107bbff6


//local emulator
import Art, Versus from 0xd796ff17107bbff6
import NonFungibleToken from 0x1d7e57aa55817448

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

