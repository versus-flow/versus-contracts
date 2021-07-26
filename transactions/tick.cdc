import Versus from "../contracts/Versus.cdc"

/*
Simulate that the clock is running
 */
transaction(dropID: UInt64) {
    prepare(account: AuthAccount) {    
      let block=getCurrentBlock()
      if let versus = account.getCapability(Versus.CollectionPublicPath).borrow<&{Versus.PublicDrop}>() {
          let versusStatus=versus.getStatus(dropId: dropID)
          log("currentBlock=".concat(block.height.toString()).concat( " currentTime=").concat(block.timestamp.toString()).concat( " endTime=").concat(versusStatus.endTime.toString()).concat(" timeRemaining=").concat(versusStatus.timeRemaining.toString()))
      }
  }
}
