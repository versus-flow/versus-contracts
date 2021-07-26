import Marketplace from "../contracts/Marketplace.cdc"
import Art from "../contracts/Art.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

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
        self.marketplace.listForSale(token: <- art, price: 5.0)
        self.marketplace.changePrice(tokenID: artId, newPrice: price)
    }
}

