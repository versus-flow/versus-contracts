import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import AuctionDutch from "../contracts/AuctionDutch.cdc"

// Transaction to increase a bid
transaction(id: UInt64, bidAmount: UFix64) {

	let dutchAuction: &AuctionDutch.BidCollection
	let temporaryVault: @FungibleToken.Vault

	prepare(account: AuthAccount) {

		self.dutchAuction=account.borrow<&AuctionDutch.BidCollection>(from: AuctionDutch.BidCollectionStoragePath) ?? panic("Could not borrow bid collection")

		let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow owner's Vault reference")

		self.temporaryVault <- vaultRef.withdraw(amount: bidAmount)
	}

	execute {
		self.dutchAuction.increaseBid(id, vault: <- self.temporaryVault)
	}
}

