import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Versus from "../contracts/Versus.cdc"

//This transaction will setup a drop in a versus auction
transaction(
    artist: Address, 
    startPrice: UFix64, 
    startTime: UFix64,
    artistName: String, 
    artName: String,
    description: String, 
    editions: UInt64,
    minimumBidIncrement: UFix64, 
    minimumBidUniqueIncrement:UFix64,
    duration:UFix64,
    extensionOnLateBid:UFix64,
    type: String, 
    artistCut: UFix64,
    minterCut: UFix64

    ) {


    let client: &Versus.Admin
    let artistWallet: Capability<&{FungibleToken.Receiver}>
    let content: String

    prepare(account: AuthAccount) {

        let path = /storage/upload
        self.content= account.load<String>(from: path) ?? panic("could not load content")
        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }
    
    execute {

			  self.client.setVersusCut(0.15)

        let art <-  self.client.mintArt(
            artist: artist,
            artistName: artistName,
            artName: artName,
            content:self.content,
            description: description, 
						type: type, 
						artistCut: artistCut, 
					 	minterCut:minterCut)

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


