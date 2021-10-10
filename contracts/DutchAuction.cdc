import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"

pub contract DutchAuction {

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath


	pub event DutchAuctionCreated(name: String, artist: String, number: Int, owner:Address, id: UInt64)
	//TODO: add human readable inptut to events
	//Not sure if we want to emit for this
	pub event DutchAuctionBid(amount: UFix64, bidder: Address, tick: UFix64, order: Int, auction: UInt64, bid: UInt64)

	pub event DutchAuctionTick(tickPrice: UFix64, acceptedBids: Int, totalItems: Int, tickTime: UFix64, auction: UInt64)
	pub event DutchAuctionSettle(price: UFix64, auction: UInt64)

	pub struct BidInfo {
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

	pub struct TickStatus{
		pub let price: UFix64
		pub let startedAt: UFix64
		pub let acceptedBids: Int
		pub let cumulativeAcceptedBids: Int

		init(price: UFix64, startedAt: UFix64, acceptedBids:Int, cumulativeAcceptedBids:Int) {
			self.price=price
			self.startedAt=startedAt
			self.acceptedBids=acceptedBids
			self.cumulativeAcceptedBids=cumulativeAcceptedBids
		}

	}

	pub resource Auction {
		access(contract) let nfts: @{UInt64:NonFungibleToken.NFT}

		access(contract) let metadata: {String:String}

		// bids are put into buckets based on the tick they are in.
		// tick 1 will be the first tick, 

		//this is a counter to keep the number of bids so that we can escrow in a separate resource
		access(contract) var totalBids: UInt64

		access(contract) var acceptedBids: Int

		//this has to be an array I think, since we need ordering. 
		access(contract) let ticks: [Tick]

		access(contract) let auctionStatus: {UFix64: TickStatus}
		access(contract) var currentTickIndex: UInt64

		access(contract) let bids: {UFix64: [BidInfo]}

		access(contract) let escrow: @{UInt64: FlowToken.Vault}

		//todo store bids here?
		access(contract) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
		access(contract) let ownerNFTCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let royaltyVaultCap: Capability<&{FungibleToken.Receiver}> 
		access(contract) let royaltyPercentage: UFix64
		access(contract) let numberOfItems: Int
		access(contract) var winningBid: UFix64?


		init(nfts: @{UInt64 : NonFungibleToken.NFT},
		metadata: {String: String},
		ownerVaultCap: Capability<&{FungibleToken.Receiver}>, 
		ownerNFTCap: Capability<&{NonFungibleToken.Receiver}>,
		royaltyVaultCap: Capability<&{FungibleToken.Receiver}>, 
		royaltyPercentage: UFix64, 
		ticks: [Tick]) {
			self.metadata=metadata
			self.totalBids=1
			self.acceptedBids=0
			self.currentTickIndex=0
			self.numberOfItems=nfts.length
			self.ticks=ticks
			self.auctionStatus={}
			//create the ticks
			self.nfts <- nfts
			self.winningBid=nil
			var emptyBids : {UFix64: [BidInfo]}={}
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
			self.winningBid=winningBid

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

		pub fun findWinners() : [BidInfo] {

			var bids: [BidInfo] =[]
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
				let nextTickStartAt= self.ticks[self.currentTickIndex+1].startedAt
				Debug.log("We are not on last tick current tick is "
				.concat(self.currentTickIndex.toString())
				.concat(" time=").concat(time.toString())
				.concat(" nextTickStart=").concat(nextTickStartAt.toString()))
				if  nextTickStartAt > time {
					return false
				}

			}
			Debug.log("we are on or after next tick")

			//TODO: need to figure out what will happen if this is the last tick
			let tick= self.getTick()

			//calculate number of acceptedBids
			let bids=self.bids[tick.startedAt]!
			let previousAcceptedBids=self.acceptedBids
			self.acceptedBids=self.acceptedBids+bids.length

			//lets advance the tick
			self.currentTickIndex=self.currentTickIndex+1

			//we have exactly or over the number of accepted bids. The auction can end!
			if self.acceptedBids >= self.numberOfItems {
				//this could be done later, but i will just do it here for ease of reading
				self.auctionStatus[tick.startedAt] = TickStatus(price:tick.price, startedAt: tick.startedAt, acceptedBids: self.numberOfItems - previousAcceptedBids, cumulativeAcceptedBids: self.numberOfItems)
				log(self.auctionStatus)

				return true
			}

			self.auctionStatus[tick.startedAt] = TickStatus(price:tick.price, startedAt: tick.startedAt, acceptedBids: bids.length, cumulativeAcceptedBids: self.acceptedBids)
			log(self.auctionStatus)


			return false
		}

		pub fun isLastTick() : Bool {
			let tickLength = UInt64(self.ticks.length-1)
			return self.currentTickIndex==tickLength
		}


		// taken from bisect_right in  pthon https://stackoverflow.com/questions/2945017/javas-equivalent-to-bisect-in-python
		pub fun bisect(items: [BidInfo], new: BidInfo) : Int{

			fun inner(items: [BidInfo], new: BidInfo, lo: Int, hi:Int) : Int {
				var high=hi
				var low=lo
				while low < high {
					let mid =(low+high)/2
					let midBid=items[mid]
					if midBid.balance < new.balance || midBid.balance==new.balance && midBid.id > new.id {
						high=mid
					} else {
						low=mid+1
					}
				}
				return low
			}

			return inner(items: items, new:new, lo:0, hi: items.length)
		}


		//this will not work well with cancelling of bids or increasing bids. I am thinking just add to tick array and sort it.
		priv fun insertBid(_ bid: BidInfo) {
			for tick in self.ticks {
				if tick.price > bid.balance {
					continue
				}

				let bucket= self.bids[tick.startedAt]!
				let index= self.bisect(items:bucket, new: bid)
				emit DutchAuctionBid(amount: bid.balance, bidder: bid.nftCap.address, tick: tick.price, order: index, auction: self.uuid, bid: bid.id)
				return 
			}
		}

		pub fun addBid(vault: @FlowToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultCap: Capability<&{FungibleToken.Receiver}>, time: UFix64) {

			let bidId=self.totalBids

			let bid=BidInfo(id: bidId, nftCap: nftCap, vaultCap:vaultCap, time: time, balance: vault.balance)
			self.insertBid(bid)
			let oldEscrow <- self.escrow[self.totalBids] <- vault
			self.totalBids=self.totalBids+(1 as UInt64)			
			destroy oldEscrow
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
		pub fun getStatus(_ id: UInt64) : DutchAuctionStatus
	}


	pub struct DutchAuctionStatus {

		pub let status: String
		pub let startTime: UFix64
		pub let currentTime: UFix64
		pub let currentPrice: UFix64
		pub let totalItems: Int
		pub let acceptedBids: Int
		pub let tickStatus: {UFix64:TickStatus}
		pub let metadata: {String:String}

		init(status:String, currentPrice: UFix64, totalItems: Int, acceptedBids:Int,  startTime: UFix64, tickStatus: {UFix64:TickStatus}, metadata: {String:String}){
			self.status=status
			self.currentPrice=currentPrice
			self.totalItems=totalItems
			self.acceptedBids=acceptedBids
			self.startTime=startTime
			self.currentTime=Clock.time()
			self.tickStatus=tickStatus
			self.metadata=metadata
		}
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
			let item= self.getAuction(id)
			let currentTime=Clock.time()

			var status="Ongoing"
			var currentPrice= item.calculatePrice()
			if currentTime < item.startAt() {
				status="NotStarted"
			} else if item.winningBid != nil {
				status="Finished"
				currentPrice=item.winningBid!
			}


			return DutchAuctionStatus(status: status, 
			currentPrice: currentPrice,
			totalItems: item.numberOfItems, 
			acceptedBids: item.acceptedBids, 
			startTime: item.startAt(),
			tickStatus: item.auctionStatus,
			metadata:item.metadata)
		}


		access(contract) fun getAuction(_ id:UInt64) : &Auction {
			pre {
				self.auctions[id] != nil: "drop doesn't exist"
			}
			return &self.auctions[id] as &Auction
		}

		//TODO: This needs to return a resource that has the Cap to this collection, auctionid and bidId.
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


		pub fun createAuction( nfts: @{UInt64: NonFungibleToken.NFT}, metadata: {String: String}, startAt: UFix64 startPrice: UFix64, floorPrice: UFix64, decreasePriceFactor: UFix64, decreasePriceAmount: UFix64, tickDuration: UFix64, ownerVaultCap: Capability<&{FungibleToken.Receiver}>, ownerNFTCap: Capability<&{NonFungibleToken.Receiver}> royaltyVaultCap: Capability<&{FungibleToken.Receiver}>, royaltyPercentage: UFix64) {

			let ticks: [Tick] = [Tick(price: startPrice, startedAt: startAt)]
			var currentPrice=startPrice
			var currentStartAt=startAt
			while(currentPrice > floorPrice) {
				currentPrice=currentPrice * decreasePriceFactor - decreasePriceAmount 
				if currentPrice < floorPrice {
					currentPrice=floorPrice
				}
				currentStartAt=currentStartAt+tickDuration
				ticks.append(Tick(price: currentPrice, startedAt:currentStartAt))
			}

			let length=nfts.keys.length

			let auction <- create Auction(nfts: <- nfts, metadata: metadata, ownerVaultCap:ownerVaultCap, ownerNFTCap:ownerNFTCap, royaltyVaultCap:royaltyVaultCap, royaltyPercentage: royaltyPercentage, ticks: ticks)

			emit DutchAuctionCreated(name: metadata["name"] ?? "Unknown name", artist: metadata["artist"] ?? "Unknown artist",  number: length, owner: ownerVaultCap.address, id: auction.uuid)

			let oldAuction <- self.auctions[auction.uuid] <- auction
			destroy oldAuction
		}

		destroy () {
			destroy self.auctions
		}

	}

	pub fun getDutchAuction(_ id: UInt64) : DutchAuctionStatus? {
		let account = DutchAuction.account
		let cap=account.getCapability<&Collection{Public}>(self.CollectionPublicPath)
		if let collection = cap.borrow() {
			return collection.getStatus(id)
		}
		return nil
	}

	pub resource Bid {

		pub let capability:Capability<&Collection{Public}>
		pub let auctionId: UInt64
		pub let bidId: UInt64

		init(capability:Capability<&Collection{Public}>, auctionId: UInt64, bidId:UInt64) {
			self.capability=capability
			self.auctionId=auctionId
			self.bidId=bidId
		}

		pub fun getBidBalance() : UFix64 {
			return 0.0 //todo
		}

		pub fun increaseBid(vault: @FungibleToken.Vault) {

			//TODO
			destroy vault
		}
		pub fun cancelBid() {

		}
	}

	pub resource BidCollection {

		access(contract) let bids : @{UInt64: Bid}

		init() {
			self.bids <- {}
		}

		pub fun addBid(_ bid: @Bid) {
			self.bids[bid.uuid] <-! bid

		}

		pub fun increaseBid(_ id: UInt64, vault: @FungibleToken.Vault) {
			let bid = self.getBid(id)


			destroy vault
		}

		access(contract) fun getBid(_ id:UInt64) : &Bid {
			pre {
				self.bids[id] != nil: "bid doesn't exist"
			}
			return &self.bids[id] as &Bid
		}

		pub fun createEmptyBidCollection() : @BidCollection {
			return <- create BidCollection()
		}


		destroy() {
			destroy  self.bids
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
