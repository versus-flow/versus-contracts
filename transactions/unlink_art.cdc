

//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7
//testnet
//import Versus from 0x01cf0e2f2f715450


transaction() {
    prepare(account: AuthAccount) {    
        //never do this.. extremely dangerous
        log("Unlinking art for ".concat(account.address.toString()))
        account.unlink(Art.CollectionPublicPath)
  }
}