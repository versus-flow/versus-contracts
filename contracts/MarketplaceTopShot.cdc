import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import TopShot from "../contracts/TopShot.cdc"
import Art from "../contracts/Art.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"

// A standard marketplace contract only hardcoded against Versus art that pay out Royalty as stored int he Art NFT

pub contract MarketplaceTopShot {

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath

	// Event that is emitted when a new NFT is put up for sale
	pub event ForSale(id: UInt64, price: UFix64, from: Address)

	// Event that is emitted when the price of an NFT changes
	pub event PriceChanged(id: UInt64, newPrice: UFix64)

	// Event that is emitted when a token is purchased
	pub event TokenPurchased(id: UInt64, artId: UInt64, price: UFix64, from:Address, to:Address)

	pub event RoyaltyPaid(id:UInt64, amount: UFix64, to:Address, name:String)

	// Event that is emitted when a seller withdraws their NFT from the sale
	pub event SaleWithdrawn(id: UInt64, from:Address)

	// Interface that users will publish for their Sale collection
	// that only exposes the methods that are supposed to be public
	//
	pub resource interface SalePublic {
		pub fun purchase(tokenID: UInt64, recipientCap: Capability<&{TopShot.MomentCollectionPublic}>, buyTokens: @FungibleToken.Vault)
		pub fun getSaleItem(tokenID: UInt64): MarketplaceData
		pub fun getIDs(): [UInt64]
		pub fun listSaleItems() : [MarketplaceData]
	}

	//TODO: might need to add more here?
	pub struct MarketplaceData {
		pub let id: UInt64
		pub let price: UFix64
		pub let metadata: {String: String}
		init( id: UInt64, price: UFix64, metadata: {String: String}) {
			self.id=id
			self.price=price
			self.metadata=metadata
		}
	}

	// SaleCollection
	//
	// NFT Collection object that allows a user to put their NFT up for sale
	// where others can send fungible tokens to purchase it
	//
	pub resource SaleCollection: SalePublic {


		access(contract) let royalty: {String: Art.Royalty}

		// Dictionary of the NFTs that the user is putting up for sale
		pub var forSale: @{UInt64: TopShot.NFT}
		pub var metadata: {UInt64: {String: String}}

		// Dictionary of the prices for each NFT by ID
		pub var prices: {UInt64: UFix64}

		// The fungible token vault of the owner of this sale.
		// When someone buys a token, this resource can deposit
		// tokens into their account.
		access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

		init (vault: Capability<&AnyResource{FungibleToken.Receiver}>, royalty: {String: Art.Royalty}) {
			self.forSale <- {}
			self.ownerVault = vault
			self.metadata={}
			self.prices = {}
			self.royalty=royalty
		}

		pub fun listSaleItems() : [MarketplaceData] {
			var saleItems: [MarketplaceData] = []

			for id in self.getIDs() {
				saleItems.append(self.getSaleItem(tokenID: id))
			}
			return saleItems
		}

		pub fun borrowMoment(id: UInt64): &TopShot.NFT? {
			if self.forSale[id] != nil {
				return &self.forSale[id] as &TopShot.NFT
			} else {
				return nil
			}
		}

		pub fun withdraw(tokenID: UInt64): @TopShot.NFT {

			let price=self.prices.remove(key: tokenID)
			// remove and return the token
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")

			emit SaleWithdrawn(id: tokenID, from: self.ownerVault.address)

			return <-token
		}

		// listForSale lists an NFT for sale in this collection
		pub fun listForSale(token: @TopShot.NFT, price: UFix64, metadata: {String: String}) {
			let id = token.id

			// store the price in the price array
			self.prices[id] = price
			self.metadata[id]=metadata

			// put the NFT into the the forSale dictionary
			let oldToken <- self.forSale[id] <- token
			destroy oldToken

			emit ForSale(id: id, price: price, from: self.ownerVault.address)
		}

		// changePrice changes the price of a token that is currently for sale
		pub fun changePrice(tokenID: UInt64, newPrice: UFix64) {
			self.prices[tokenID] = newPrice
			emit PriceChanged(id: tokenID, newPrice: newPrice)
		}

		// purchase lets a user send tokens to purchase an NFT that is for sale
		pub fun purchase(tokenID: UInt64, recipientCap: Capability<&{TopShot.MomentCollectionPublic}>, buyTokens: @FungibleToken.Vault) {
			pre {
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
				"No token matching this ID for sale!"
				buyTokens.balance >= (self.prices[tokenID] ?? 0.0):
				"Not enough tokens to by the NFT!"
			}

			let recipient=recipientCap.borrow()!

			// get the value out of the optional
			let price = self.prices[tokenID]!

			self.prices[tokenID] = nil

			let vaultRef = self.ownerVault.borrow()
			?? panic("Could not borrow reference to owner token vault")

			let token <-self.withdraw(tokenID: tokenID)
			let artId = token.id

			for royality in self.royalty.keys {
				let royaltyData= self.royalty[royality]!
				if let wallet= royaltyData.wallet.borrow() {
					let amount= price * royaltyData.cut
					let royaltyWallet <- buyTokens.withdraw(amount: amount)
					wallet.deposit(from: <- royaltyWallet)
					emit RoyaltyPaid(id: tokenID, amount:amount, to: royaltyData.wallet.address, name:royality)
				} 
			}
			// deposit the purchasing tokens into the owners vault
			vaultRef.deposit(from: <-buyTokens)

			// deposit the NFT into the buyers collection
			recipient.deposit(token: <- token)

			emit TokenPurchased(id: tokenID, artId: artId, price: price, from: vaultRef.owner!.address, to:  recipient.owner!.address)
		}

		// idPrice returns the price of a specific token in the sale
		pub fun getSaleItem(tokenID: UInt64): MarketplaceData {

			return MarketplaceData(
				id: tokenID,
				price: self.prices[tokenID]!,
				metadata: self.metadata[tokenID]!
			)
		}

		// getIDs returns an array of token IDs that are for sale
		pub fun getIDs(): [UInt64] {
			return self.forSale.keys
		}

		destroy() {
			destroy self.forSale
		}
	}

	// createCollection returns a new collection resource to the caller
	pub fun createSaleCollection(ownerVault: Capability<&{FungibleToken.Receiver}>): @SaleCollection {

		  
		//TODO: change topshot to anohter wallet!
		  let minterWallet= MarketplaceTopShot.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			let royalty = {
				"topshot" : Art.Royalty(wallet: minterWallet, cut: 0.05),
				"versus" : Art.Royalty(wallet: minterWallet, cut: 0.025)
			}

			return <- create SaleCollection(vault: ownerVault, royalty:royalty)
	}

	pub init() {
		self.CollectionPublicPath= /public/versusArtMarketplace
		self.CollectionStoragePath= /storage/versusArtMarketplace
	}

}

