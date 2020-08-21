//This transaction will setup a drop in a versus auction
//Currently all art is minted inside the contract

import NonFungibleToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31
import Auction from 0xe03daebed8ca0615
import Versus from 0x045a1763c93006ca
import Art from 0xf3fcd2c1a78f5eee

transaction(
    artist: Address, 
    startPrice: UFix64, 
    startBlock: UInt64,
    artistName: String, 
    artName: String, 
    url: String, 
    description: String, 
    editions: UInt64,
    minimumBidIncrement: UFix64) {


    let artistWallet: Capability<&{FungibleToken.Receiver}>
    let versus: &Versus.DropCollection

    prepare(account: AuthAccount) {

        self.versus= account.borrow<&Versus.DropCollection>(from: /storage/Versus)!
        
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!
        if !self.artistWallet.check() {
            panic("Unable to borrow the Vault Receiver capability")
         }
       
    }

    execute {

        var metadata: {String: String} = {
            "name" : artName, 
            "artist" : artistName,
            "artistAddress" : artist.toString(),
            "url" : url,
            "description": description
        }
        
       self.versus.createDrop(
           artMetadata: metadata,
           editions: editions,
           minimumBidIncrement: minimumBidIncrement,
           startBlock: startBlock,
           startPrice: startPrice,
           vaultCap: self.artistWallet
       )
    }
}
 