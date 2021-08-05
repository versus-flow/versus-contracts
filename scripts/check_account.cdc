import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Art from "../contracts/Art.cdc"

pub struct AddressStatus {

  pub(set) var address:Address
  pub(set) var flowBalance: UFix64
  pub(set) var fusdBalance: UFix64
  pub(set) var art: [Art.ArtData]
  init (_ address:Address) {
    self.address=address
    self.fusdBalance= 0.0
    self.flowBalance= 0.0
    self.art= []
  }
}

/*
   This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(address:Address) : AddressStatus {
  // get the accounts' public address objects
  let account = getAccount(address)
  let status= AddressStatus(address)

  if let vault= account.getCapability(/public/flowTokenBalance).borrow<&{FungibleToken.Balance}>() {
    status.flowBalance=vault.balance
  }

  if let fusd= account.getCapability(/public/fusdBalance).borrow<&{FungibleToken.Balance}>() {
    status.fusdBalance=fusd.balance
  }

  status.art= Art.getArt(address: address)

  return status

}
