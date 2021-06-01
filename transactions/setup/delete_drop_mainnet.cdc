
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0


//local emulator
import Versus from 0xd796ff17107bbff
//This transaction will setup a drop in a versus auction
transaction(id: UInt64) {


    let versus: &Versus.DropCollection

    prepare(account: AuthAccount) {

        self.versus= account.borrow<&Versus.DropCollection>(from: Versus.CollectionStoragePath)!
    }
    
    execute {

        let drop <- self.versus.drops[id] <- nil
        destroy drop

    }
}

