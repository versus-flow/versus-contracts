import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61
import Versus from 0xd796ff17107bbff6

//This transactions transfers flow on testnet from one account to another
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