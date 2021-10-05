import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import Art from "./Art.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"

pub contract DutchAuction {

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath


	pub event DutchAuctionCreated(name: String, artist: String, number: Int, owner:Address, id: UInt64)
	//TODO: add human readable inptut to events
	//Not sure if we want to emit for this
	//pub event DutchAuctionBid(amount: UFix64, bidder: Address, tick: UFix64, order: Int, auction: UInt64, bid: UInt64)

	pub event DutchAuctionTick(tickPrice: UFix64, acceptedBids: Int, totalItems: Int, tickTime: UFix64, auction: UInt64)
	pub event DutchAuctionSettle(price: UFix64, auction: UInt64)

	pub struct DutchAuctionStatus {

		pub let status: String
		pub let startedAt: UFix64
		pub let currentTime: UFix64
		pub let currentPrice: UFix64
		pub let totalItems: Int
		pub let acceptedBids: Int


		init(status:String, currentPrice: UFix64, totalItems: Int, acceptedBids:Int,  startedAt: UFix64){
			self.status=status
			self.currentPrice=currentPrice
			self.totalItems=totalItems
			self.acceptedBids=acceptedBids
			self.startedAt=startedAt
			self.currentTime=Clock.time()
		}
	}

	pub struct Bid {
		access(contract) let id: UInt64
		access(contract) let vaultCap: Capability<&{FungibleToken.Receiver}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let time: UFix64
		access(contract) let balance: UFix64


		init(id: UInt64, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultCap: Capability<&{FungibleToken.Receiver}>, time: UFix64, balance: UFix64) {
			self.id=id
			self.nftCap= nftCap
			self.vaultCap=vaultCap
			self.time=time
			self.balance=balance
		}
	}

	pub struct Tick {
		pub let price: UFix64
		pub let startedAt: UFix64

		init(price: UFix64, startedAt: UFix64) {
			self.price=price
			self.startedAt=startedAt
		}
	}

	pub resource Auction{

		//todo should this just be a Art.Collection?
		//TODO: this cannot be very large depending on gas and complexity
		access(contract) let nfts: @{UInt64:Art.NFT}

		//TODO: add metadata dictionary

		// bids are put into buckets based on the tick they are in.
		// tick 1 will be the first tick, 

		//this is a counter to keep the number of bids so that we can escrow in a separate resource
		access(contract) var totalBids: UInt64

		access(contract) var acceptedBids: Int

		//this has to be an array I think, since we need ordering. 
		access(contract) let ticks: [Tick]

		access(contract) var currentTickIndex: UInt64

		access(contract) let bids: {UFix64: [Bid]}

		access(contract) let escrow: @{UInt64: FlowToken.Vault}

		//todo store bids here?
		access(contract) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
		access(contract) let ownerNFTCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let royaltyVaultCap: Capability<&{FungibleToken.Receiver}> 
		access(contract) let royaltyPercentage: UFix64
		access(contract) let numberOfItems: Int


		init(nfts: @{UInt64 : Art.NFT},
		ownerVaultCap: Capability<&{FungibleToken.Receiver}>, 
		ownerNFTCap: Capability<&{NonFungibleToken.Receiver}>
		royaltyVaultCap: Capability<&{FungibleToken.Receiver}>, 
		royaltyPercentage: UFix64, 
		ticks: [Tick]) {
			self.totalBids=1
			self.acceptedBids=0
			self.currentTickIndex=0
			self.numberOfItems=nfts.length
			self.ticks=ticks
			//create the ticks
			self.nfts <- nfts
			var emptyBids : {UFix64: [Bid]}={}
			for tick in ticks {
				emptyBids[tick.startedAt]=[]
			}
			self.bids = emptyBids
			self.escrow <- {}
			self.ownerVaultCap=ownerVaultCap
			self.ownerNFTCap=ownerNFTCap
			self.royaltyVaultCap=royaltyVaultCap
			self.royaltyPercentage=royaltyPercentage
		}

		pub fun startAt() : UFix64 {
			return self.ticks[0].startedAt
		}

		pub fun fullfill() {
			let winners=self.findWinners()

			let winningBid=winners[winners.length-1].balance

			let nftIds= self.nfts.keys

			for winner in winners {
				if let vault <- self.escrow[winner.id] <- nil {

					if vault.balance > winningBid {
						self.ownerVaultCap.borrow()!.deposit(from: <- vault.withdraw(amount: vault.balance-winningBid))
					}
					if self.royaltyPercentage != 0.0 {
						self.royaltyVaultCap.borrow()!.deposit(from: <- vault.withdraw(amount: vault.balance*self.royaltyPercentage))
					}

					//TODO: fix if unlinked, or maybe just fail then?
					self.ownerVaultCap.borrow()!.deposit(from: <- vault)

					let nftId=nftIds.removeFirst()
					if let nft <- self.nfts[nftId] <- nil {
						winner.nftCap.borrow()!.deposit(token: <- nft)
					}
				}
			}
			//let just return all other money here and fix the issue with gas later
			//this will blow the gas limit on high number of bids
			for tick in self.ticks {
				if let bids=self.bids[tick.startedAt]{
					for bid in bids {
						if let vault <- self.escrow[bid.id] <- nil {
							//TODO: check that it is still linked
							bid.vaultCap.borrow()!.deposit(from: <- vault)		
						}
					}
				}
			}

			emit DutchAuctionSettle(price: winningBid, auction: self.uuid)
		}

		pub fun findWinners() : [Bid] {

			var bids: [Bid] =[]
			for tick in self.ticks {
				if bids.length == self.numberOfItems {
					return bids
				}
				let localBids=self.bids[tick.startedAt]!
				if bids.length+localBids.length <= self.numberOfItems {
					bids.appendAll(localBids)
					//we have to remove the bids
					self.bids.remove(key: tick.startedAt)
				} else {
					while bids.length < self.numberOfItems {
						bids.append(localBids.removeFirst())
					}
				}
			}
			return bids
		}

		pub fun getTick() : Tick {
			return self.ticks[self.currentTickIndex]
		}

		pub fun isAuctionFinished() : Bool {
			//if we are on the last tick we do not increment the tick anymore we just check again and again if we have the right amount of bids

			if !self.isLastTick() {
				//if the startedAt of the next tick is larger then current time not time to tick yet
				let time=Clock.time()
				let nextTickStartAt= self.ticks[self.currentTickIndex+1]!.startedAt
				Debug.log("We are not on last tick current tick is "
				.concat(self.currentTickIndex.toString())
				.concat(" time=").concat(time.toString())
				.concat(" nextTickStart=").concat(nextTickStartAt.toString())
			)
			if  nextTickStartAt > time {
				return false
			}

		}
		Debug.log("we are on or after next tick")

		//TODO: need to figure out what will happen if this is the last tick
		let tick= self.getTick()

		//calculate number of acceptedBids
		let bids=self.bids[tick.startedAt]!
		self.acceptedBids=self.acceptedBids+bids.length

		//lets advance the tick
		self.currentTickIndex=self.currentTickIndex+1

		//we have exactly or over the number of accepted bids. The auction can end!
		if self.acceptedBids >= self.numberOfItems {
			return true
		}

		return false
	}

	pub fun isLastTick() : Bool {
		let tickLength = UInt64(self.ticks.length-1)
		return self.currentTickIndex==tickLength
	}

	priv fun insertBid(_ bid: Bid) {
		for tick in self.ticks {
			if tick.price > bid.balance {
				continue
			}
			let bucket= self.bids[tick.startedAt]!
			var bidIndex=0
			//TODO: implement more efficient sorting algorithm
			while bidIndex < bucket.length {
				let oldBid=bucket[bidIndex]

				//new bid is larger then the old one so we insert it before
				if oldBid.balance < bid.balance {
					bucket.insert(at: bidIndex, bid)
					//emit DutchAuctionBid(amount: bid.balance, bidder: bid.nftCap.address, tick: tick.price, order: bidIndex, auction: self.uuid, bid: bid.id)
					self.bids[tick.startedAt] = bucket
					Debug.log("Bid larger index=".concat(bidIndex.toString())
						.concat(" amount=").concat(bid.balance.toString())
						.concat(" tick=").concat(tick.price.toString())
						.concat(" bidder=").concat(bid.nftCap.address.toString())
						.concat(" bidid=").concat(bid.id.toString())
						.concat(" bidSize=").concat(self.bids[tick.startedAt]!.length.toString()))
					return
					//new bid is same balance but made earlier so we insert before
				}

				//TODO: This will never happen I think
				if oldBid.balance==bid.balance && oldBid.time < bid.time {
					bucket.insert(at: bidIndex, bid)
					self.bids[tick.startedAt] = bucket
					//emit DutchAuctionBid(amount: bid.balance, bidder: bid.nftCap.address, tick: tick.price, order: bidIndex, auction: self.uuid, bid: bid.id)
					Debug.log("Bid earlier index=".concat(bidIndex.toString())
						.concat(" amount=").concat(bid.balance.toString())
						.concat(" tick=").concat(tick.price.toString())
						.concat(" bidder=").concat(bid.nftCap.address.toString())
						.concat(" bidid=").concat(bid.id.toString())
						.concat(" bidSize=").concat(self.bids[tick.startedAt]!.length.toString()))
					return
				}
				bidIndex=bidIndex+1
			}

			self.bids[tick.startedAt]!.append(bid)

			let lastIndex=self.bids[tick.startedAt]!.length-1 
Debug.log("Bid smallest index=".concat(lastIndex.toString())
						.concat(" amount=").concat(bid.balance.toString())
						.concat(" tick=").concat(tick.price.toString())
						.concat(" bidder=").concat(bid.nftCap.address.toString())
						.concat(" bidid=").concat(bid.id.toString())
						.concat(" bidSize=").concat(self.bids[tick.startedAt]!.length.toString()))
			//emit DutchAuctionBid(amount: bid.balance, bidder: bid.nftCap.address, tick: tick.price, order: lastIndex, auction: self.uuid, bid: bid.id)
			return 
		}
	}

	pub fun addBid(vault: @FlowToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultCap: Capability<&{FungibleToken.Receiver}>, time: UFix64) {

		let bidId=self.totalBids

		let bid=Bid(id: bidId, nftCap: nftCap, vaultCap:vaultCap, time: time, balance: vault.balance)
		self.insertBid(bid)
		let oldEscrow <- self.escrow[self.totalBids] <- vault
		self.totalBids=self.totalBids+(1 as UInt64)			
		destroy oldEscrow
	}

	pub fun  hasEnoughBids() : Bool {
		return self.numberOfItems==self.acceptedBids
	}

	pub fun calculatePrice() : UFix64{
		return self.ticks[self.currentTickIndex].price
	}

	destroy() {
		//TODO: deposity to ownerNFTCap
		destroy self.nfts
		//todo transfer back
		destroy self.escrow
	}
}

pub resource interface Public {
	pub fun bid(id: UInt64, vault: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, nftCap: Capability<&{NonFungibleToken.Receiver}>)
	pub fun getIds() : [UInt64] 
	//TODO: get DutchAuctionStatus
	//TODO this should either fetch from active auction dict or finishedAuctionDict
}

pub resource Collection: Public {

	//TODO: what to do with ended auctions? put them in another collection?
	//NFTS are gone but we might want to keep some information about it?		

	pub let auctions: @{UInt64: Auction}

	init() {
		self.auctions <- {}
	}

	pub fun getIds() : [UInt64] {
		return self.auctions.keys
	}

	pub fun getStatus(_ id: UInt64) : DutchAuctionStatus{
		//TODO handle ended auction
		let item= self.getAuction(id)
		let currentTime=Clock.time()

		var status="Ongoing"
		if currentTime > item.startAt() {
			status="NotStarted"
		} 

		return DutchAuctionStatus(status: status, currentPrice: item.calculatePrice(), totalItems: item.numberOfItems, acceptedBids: item.acceptedBids, startedAt: item.startAt())
	}


	access(contract) fun getAuction(_ id:UInt64) : &Auction {
		pre {
			self.auctions[id] != nil: "drop doesn't exist"
		}
		return &self.auctions[id] as &Auction
	}

	pub fun bid(id: UInt64, vault: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
		//TODO: pre id should exist

		let time=Clock.time()
		let vault <- vault as! @FlowToken.Vault
		let auction=self.getAuction(id)

		let price=auction.calculatePrice()

		//the currentPrice is still higher then your bid, this is find we just add your bid to the correct tick bucket
		if price > vault.balance {
			auction.addBid(vault: <- vault, nftCap:nftCap, vaultCap: vaultCap, time: time)
			return
		}

		let tooMuchCash=vault.balance - price
		//you sent in too much flow when you bid so we return some to you and add a valid accepted bid
		if tooMuchCash != 0.0 {
			vaultCap.borrow()!.deposit(from: <- vault.withdraw(amount: tooMuchCash))
		}

		auction.addBid(vault: <- vault, nftCap:nftCap, vaultCap: vaultCap, time: time)

	}

	pub fun tickOrFullfill(_ id:UInt64) {
		let time=Clock.time()
		let auction=self.getAuction(id)

		if !auction.isAuctionFinished() {
			let tick=auction.getTick()
			emit DutchAuctionTick(tickPrice: tick.price, acceptedBids: auction.acceptedBids, totalItems: auction.numberOfItems, tickTime: tick.startedAt, auction: id)
			return
		}
		auction.fullfill()
	}


	pub fun createAuction( nfts: @{UInt64: Art.NFT}, startAt: UFix64 startPrice: UFix64, floorPrice: UFix64, decreasePriceFactor: UFix64, decreasePriceAmount: UFix64, tickDuration: UFix64, ownerVaultCap: Capability<&{FungibleToken.Receiver}>, ownerNFTCap: Capability<&{NonFungibleToken.Receiver}> royaltyVaultCap: Capability<&{FungibleToken.Receiver}>, royaltyPercentage: UFix64) {

		let ticks: [Tick] = [Tick(price: startPrice, startedAt: startAt)]
		var currentPrice=startPrice
		var currentStartAt=startAt
		while(currentPrice > floorPrice) {
			//TODO: is this correct?
			currentPrice=currentPrice * decreasePriceFactor - decreasePriceAmount 
			if currentPrice < floorPrice {
				currentPrice=floorPrice
			}
			currentStartAt=currentStartAt+tickDuration
			ticks.append(Tick(price: currentPrice, startedAt:currentStartAt))
		}

		let length=nfts.keys.length

		let auction <- create Auction(nfts: <- nfts,ownerVaultCap:ownerVaultCap, ownerNFTCap:ownerNFTCap, royaltyVaultCap:royaltyVaultCap, royaltyPercentage: royaltyPercentage, ticks: ticks)

		emit DutchAuctionCreated(name: "TODO", artist: "TODO",  number: length, owner: ownerVaultCap.address, id: auction.uuid)

		let oldAuction <- self.auctions[auction.uuid] <- auction
		destroy oldAuction
	}

	destroy () {
		destroy self.auctions
	}

}

init() {
	self.CollectionPublicPath= /public/versusDutchAuctionCollection
	self.CollectionStoragePath= /storage/versusDutchAuctionCollection


	let account=self.account
	let collection <- create Collection()
	account.save(<-collection, to: DutchAuction.CollectionStoragePath)
	account.link<&Collection{Public}>(DutchAuction.CollectionPublicPath, target: DutchAuction.CollectionStoragePath)

}
}
