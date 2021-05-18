
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus from 0xd796ff17107bbff60


//import NonFungibleToken, Art from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0x1d7e57aa55817448
import Art from 0xd796ff17107bbff6

//This transaction will setup a drop in a versus auction
transaction() {
    prepare(account: AuthAccount) {
        account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)
        account.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)
    }

}

