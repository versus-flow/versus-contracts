
//testnet
//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import Content, Art, Auction, Versus, Marketplace from 0x1ff7e32d71183db0

//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus, Marketplace from 0xf8d6e0586b0a20c7

//TODO: This is not done, need to mint art first and then add it to the sale collection

//this transaction will setup an newly minted item for sale
transaction(
    artId: UInt64
    price: UFix64) {

    let artCollection:&Art.Collection
    let marketplace: &Marketplace.SaleCollection

    prepare(account: AuthAccount) {


        let marketplaceCap = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
        // if sale collection is not created yet we make it.
        if !marketplaceCap.check() {
             let wallet=  account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
             let sale <- Marketplace.createSaleCollection(ownerVault: wallet)

            // store an empty NFT Collection in account storage
            account.save<@Marketplace.SaleCollection>(<- sale, to:Marketplace.CollectionStoragePath)

            // publish a capability to the Collection in storage
            account.link<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath, target: Marketplace.CollectionStoragePath)
        }

        self.marketplace=account.borrow<&Marketplace.SaleCollection>(from: Marketplace.CollectionStoragePath)!
        self.artCollection= account.borrow<&Art.Collection>(from: Art.CollectionStoragePath)!
    }

    execute {
        let art <- self.artCollection.withdraw(withdrawID: artId) as! @Art.NFT
        self.marketplace.listForSale(token: <- art, price: price)
    }
}

