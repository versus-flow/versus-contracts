import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Versus from "../contracts/Versus.cdc"
import Art from "../contracts/Art.cdc"

//This transaction will setup a drop in a versus auction
transaction(
    artist: Address, 
		minter: Address,
    startPrice: UFix64, 
    startTime: UFix64,
    artistName: String, 
    artName: String,
    description: String, 
		ipfsHash:String,
    editions: UInt64,
    minimumBidIncrement: UFix64, 
    minimumBidUniqueIncrement:UFix64,
    duration:UFix64,
    extensionOnLateBid:UFix64,
    type: String, 
    artistCut: UFix64,
    minterCut: UFix64
    ftReceiverPath: PublicPath
    ) {


    let client: &Versus.Admin
    let artistWallet: Capability<&{FungibleToken.Receiver}>

    prepare(account: AuthAccount) {
      self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
      self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(ftReceiverPath)
    }

  execute {


    let art <-  self.client.mintArt(
        artist: artist,
        artistName: artistName,
        artName: artName,
        content:ipfsHash,
        description: description, 
        type: type, 
        artistCut: artistCut, 
        minterCut:minterCut, 
        receiverPath: ftReceiverPath)

       self.client.createDrop(
          nft:  <- art,
          editions: editions,
          minimumBidIncrement: minimumBidIncrement,
          minimumBidUniqueIncrement: minimumBidUniqueIncrement,
          startTime: startTime,
          startPrice: startPrice,
          vaultCap: self.artistWallet,
          duration: duration,
          extensionOnLateBid: extensionOnLateBid 
          )
  }
}


