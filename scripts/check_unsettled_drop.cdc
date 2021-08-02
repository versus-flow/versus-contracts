  
import Versus from "../contracts/Versus.cdc"

pub fun main(owner:Address) : UInt64? {
  let account = getAccount(owner)
  let versusCap=account.getCapability<&{Versus.PublicDrop}>(Versus.CollectionPublicPath)
  if let versus = versusCap.borrow() {
      let versusStatuses=versus.getAllStatuses()
      for s in versusStatuses.keys {
         let status = versusStatuses[s]!
         if status.active == false && status.expired==true && status.settledAt == nil {
           return status.dropId
         } 
      } 
  }
  return nil
}
