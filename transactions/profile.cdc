import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FUSD from "../../contracts/standard/FUSD.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import NonFungibleToken from "../../contracts/standard/NonFungibleToken.cdc"
import Art from "../../contracts/Art.cdc"
import Versus from "../../contracts/Versus.cdc"
import Profile from "../../contracts/Profile.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"

transaction(name: String, description: String, allowStoringFollowers: Bool) {
  prepare(acct: AuthAccount) {

    let profile <-Profile.createUser(name:name, description: description, allowStoringFollowers:allowStoringFollowers, tags:["versus"])

    //adding existing flowToken wallet
    let flowReceiver= acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    let flowBalance= acct.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance)
    let flow=acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
    let flowWallet= Profile.Wallet(name:"Flow", receiver: flowReceiver, balance: flowBalance, accept:flow.getType(), tags: ["flow"])
    profile.addWallet(flowWallet)


    //Add exising FUSD or create a new one and add it
    let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
    if !fusdReceiver.check() {
      let fusd <- FUSD.createEmptyVault()
      let fusdType=fusd.getType()
      acct.save(<- fusd, to: /storage/fusdVault)
      acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
      acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
    }
    let fusdWallet=Profile.Wallet(
        name:"FUSD", 
        receiver:fusdReceiver,
        balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
        accept: fusdType,
        tags: ["fusd", "stablecoin"]
    )
    profile.addWallet(fusdWallet)


    //Create versus art collection if it does not exist and add it
    let artCollectionCap=acct.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
    if !artCollectionCap.check() {
      acct.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)
      acct.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)
    }
    profile.addCollection(Profile.ResourceCollection( 
        name: "VersusArt", 
        collection:artCollectionCap, 
        type: Type<&{Art.CollectionPublic}>(),
        tags: ["versus", "nft"]))

    let marketplaceCap = acct.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
    if !marketplaceCap.check() {
      let sale <- Marketplace.createSaleCollection(ownerVault: flowReceiver)
      acct.save<@Marketplace.SaleCollection>(<- sale, to:Marketplace.CollectionStoragePath)
      acct.link<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath, target: Marketplace.CollectionStoragePath)
    }
    profile.addCollection(Profile.ResourceCollection(
        "VersusMarketplace", 
        marketplaceCap, 
        Type<&{Marketplace.SalePublic}>(),
        ["versus", "marketplace"]))


    acct.save(<-profile, to: Profile.storagePath)
    acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
  }
}

