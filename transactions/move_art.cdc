
import NonFungibleToken from 0x1d7e57aa55817448
import Art from 0xd796ff17107bbff6

transaction(address:Address, artID: UInt64) {


  let nftCollection: &NonFungibleToken.Collection

  prepare(account: AuthAccount) {
    self.nftCollection =account.borrow<&NonFungibleToken.Collection>(from: Art.CollectionStoragePath)!
  }

  execute {
      let versusCollection : &{Art.CollectionPublic} = getAccount(address).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath).borrow()!
      let art <- self.nftCollection.withdraw(withdrawID:artID)
      versusCollection.deposit(token: <- art)
  }
}