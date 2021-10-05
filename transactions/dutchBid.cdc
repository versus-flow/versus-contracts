import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Versus from "../contracts/Versus.cdc"
import DutchAuction from "../contracts/DutchAuction.cdc"
import Art from "../contracts/Art.cdc"

// Transaction to make a bid in a marketplace for the given dropId and auctionId
transaction(marketplace: Address, id: UInt64, bidAmount: UFix64) {
	// reference to the buyer's NFT collection where they
	// will store the bought NFT

	let vaultCap: Capability<&{FungibleToken.Receiver}>
	let collectionCap: Capability<&{NonFungibleToken.Receiver}> 
	let dutchAuctionCap: Capability<&DutchAuction.Collection{DutchAuction.Public}>
	let temporaryVault: @FungibleToken.Vault

	prepare(account: AuthAccount) {

		// get the references to the buyer's Vault and NFT Collection receiver
		let collectionCap=  account.getCapability<&{NonFungibleToken.Receiver}>(Art.CollectionPublicPathStandard)

		// if collection is not created yet we make it.
		if !collectionCap.check() {
			account.unlink(Art.CollectionPublicPathStandard)
			account.unlink(Art.CollectionPublicPath)
			destroy <- account.load<@AnyResource>(from:Art.CollectionStoragePath)
			// store an empty NFT Collection in account storage
			account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)

			// publish a capability to the Collection in storage
			account.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)

			//publish the standard link
			account.link<&{NonFungibleToken.Receiver}>(Art.CollectionPublicPathStandard, target: Art.CollectionStoragePath)
		}

		self.collectionCap=collectionCap

		self.vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		self.dutchAuctionCap=	getAccount(marketplace).getCapability<&DutchAuction.Collection{DutchAuction.Public}>(DutchAuction.CollectionPublicPath)

		let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow owner's Vault reference")

		self.temporaryVault <- vaultRef.withdraw(amount: bidAmount)
	}

	execute {
		self.dutchAuctionCap.borrow()!.bid(id: id, vault: <- self.temporaryVault, vaultCap: self.vaultCap, nftCap: self.collectionCap)
	}
}
