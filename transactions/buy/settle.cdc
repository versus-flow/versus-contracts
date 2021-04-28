
//emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Versus from 0x1ff7e32d71183db0
/*
Transaction to settle/finish off an auction. Has to be signed by the owner of the versus marketplace
 */
transaction(dropId: UInt64) {

    let client: &Versus.Admin
    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
    }

    execute {
        self.client.settle(dropId)
    }
}
 