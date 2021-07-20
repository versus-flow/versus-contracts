import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import Versus from "../../contracts/Versus.cdc"

//This transactions transfers flow on from versus to another user
transaction(amount: UFix64, to: Address) {
  let sentVault: @FungibleToken.Vault

  prepare(signer: AuthAccount) {
    let client = signer.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
    self.sentVault <- client.getFlowWallet().withdraw(amount: amount)
  }

  execute {
    let recipient = getAccount(to)
    let receiverRef = recipient.getCapability(/public/flowTokenReceiver)!.borrow<&{FungibleToken.Receiver}>()
      ?? panic("Could not borrow receiver reference to the recipient's Vault")

    receiverRef.deposit(from: <-self.sentVault)
  }
}
