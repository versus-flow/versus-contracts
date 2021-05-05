  
import Versus from 0xd796ff17107bbff6

pub fun main() : UInt64? {
  let account = getAccount(0xd796ff17107bbff6)
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