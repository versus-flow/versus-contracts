//todo, update this when the contract is updated on testnet
//a copy of the drop transaction on testnet
//testnet
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0xdb47998bf96c9ef1


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

        let art <-  self.client.mintArt(
            artist: artist,
            artistName: artistName,
            artName: artName,
            content:self.content,
            description: description)

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


