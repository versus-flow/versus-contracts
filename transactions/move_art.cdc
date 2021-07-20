
import NonFungibleToken from "../../contracts/standard/NonFungibleToken.cdc"
import Art from "../../contracts/Art.cdc"

//Transaction to move a NFT art from the signers collection to another collection
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
