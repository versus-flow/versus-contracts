
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0


//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7
//This transaction will setup a drop in a versus auction

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
    duration:UFix64
    ) {


    let client: &Versus.Admin
    let artistWallet: Capability<&{FungibleToken.Receiver}>
    let content: String

    prepare(account: AuthAccount) {

        let path = /storage/upload
        self.content= account.load<String>(from: path) ?? panic("could not load upload storage")
        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }
    
    execute {


        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:self.content, description: description)

        self.client.createDrop(
           nft:  <- art,
           editions: editions,
           minimumBidIncrement: minimumBidIncrement,
           minimumBidUniqueIncrement: minimumBidUniqueIncrement,
           startTime: startTime,
           startPrice: startPrice,
           vaultCap: self.artistWallet,
           duration: duration,
           extensionOnLateBid: duration
       )

       let content=self.client.getContent()
       log(content.contents.keys)

       let wallet=self.client.getFlowWallet()
       log(wallet.balance)


    }
}


