
//testnet
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0


//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7
//This transaction will setup a drop in a versus auction
transaction(
    artist: Address, 
    artistName: String, 
    artName: String, 
    url: String, 
    description: String) {


    let artistWallet: Capability<&{FungibleToken.Receiver}>
    let contentCapability: Capability<&Content.Collection>
    let artistCollection: Capability<&{Art.CollectionPublic}>
    let artAdmin:&Art.Administrator

    prepare(account: AuthAccount) {

        let artistAccount=getAccount(artist)
        self.contentCapability=account.getCapability<&Content.Collection>(Content.CollectionPrivatePath)
        self.artistWallet=  artistAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        self.artistCollection= artistAccount.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
        self.artAdmin=account.borrow<&Art.Administrator>(from: Art.AdministratorStoragePath)!
    }

    execute {

        var contentItem  <- Content.createContent(url)
        let contentId= contentItem.id
        self.contentCapability.borrow()!.deposit(token: <- contentItem)

         let royalty = {
            "artist" : Art.Royalty(wallet: self.artistWallet, cut: 0.05)
        }
        let art <- self.artAdmin.createArtWithPointer(
            name: artName,
            artist:artistName,
            artistAddress : artist,
            description: description,
            type: "png",
            contentCapability: self.contentCapability,
            contentId: contentId,
            royalty: royalty
        )

        self.artistCollection.borrow()!.deposit(token: <- art)
    }
}

