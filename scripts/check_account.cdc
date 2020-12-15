// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: DemoToken Vault Balance = 1050, No NFTs
// Account 0x02: DemoToken Vault Balance = 10, NFT.id = 1

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, DemoToken, Art, Auction, Versus from 0x01cf0e2f2f715450

pub struct AddressStatus {

  pub(set) var address:Address
  pub(set) var balance: UFix64
  pub(set) var art: {UInt64: {String : String}}
  pub(set) var drops: {UInt64: Versus.DropStatus}
  init (_ address:Address) {
    self.address=address
    self.balance= UFix64(0)
    self.art= {}
    self.drops ={}
  }
}

/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(address:Address, name: String){
    // get the accounts' public address objects
    let account = getAccount(address)
    let status= AddressStatus(address)
    log(name)
    log("=====================")
    
    if let demoTokenCapability =account.getCapability(/public/DemoTokenBalance) {
        if let demoTokens= demoTokenCapability.borrow<&{FungibleToken.Balance}>() {
          log("Balance of DemoTokens")
          log(demoTokens.balance)
          status.balance=demoTokens.balance
        }
    }
    if let versusCap = account.getCapability(/public/Versus) {

        if let versus = versusCap.borrow<&{Versus.PublicDrop}>() {
          log("Drops available")
          log("=================")
          let versusStatuses=versus.getAllStatuses()
          for s in versusStatuses.keys {
             let status = versusStatuses[s]!
             if status.uniqueStatus.active != false {
                log("dropid")
                log(status.dropId)
                log("Price unique")
                log(status.uniquePrice)
                log("Price editioned")
                log(status.editionPrice)
                log("Winning")
                log(status.winning)
                log(status.uniqueStatus)
                for es in status.editionsStatuses.keys {
                    let es = status.editionsStatuses[es]!
                    log(es)
                }
             }
          }
          status.drops=versusStatuses
          return
        } 
    } 

    if let artCap = account.getCapability(/public/ArtCollection) {
       if let art= artCap.borrow<&{NonFungibleToken.CollectionPublic}>()  {
           log("Art in collection") 
           for id in art.getIDs() {
             var metadata=art.borrowNFT(id: id).metadata
             log(metadata)
             status.art[id]=metadata
           }
       }
    }
    
    log("=====================")
    //return status

}
