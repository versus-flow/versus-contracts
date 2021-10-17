import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"

pub contract AuctionDutch {

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath

	pub let BidCollectionStoragePath: StoragePath
	pub let BidCollectionPublicPath: PublicPath


	pub event AuctionDutchBidRejected(bidder: Address)
	pub event AuctionDutchCreated(name: String, artist: String, number: Int, owner:Address, id: UInt64)
	//TODO: add human readable inptut to events, need to know what ts metadata we add here
	pub event AuctionDutchBid(amount: UFix64, bidder: Address, auction: UInt64, bid: UInt64)
	pub event AuctionDutchBidIncreased(amount: UFix64, bidder: Address, auction: UInt64, bid: UInt64)
	pub event AuctionDutchTick(tickPrice: UFix64, acceptedBids: Int, totalItems: Int, tickTime: UFix64, auction: UInt64)
	pub event AuctionDutchSettle(price: UFix64, auction: UInt64)

	pub struct Bids {
		pub let bids: [BidReport]
		pub let winningPrice: UFix64?

		init(bids: [BidReport], winningPrice: UFix64?) {
			self.bids =bids
			self.winningPrice=winningPrice
		}
	}

	pub struct BidReport {
		pub let id: UInt64
		pub let time: UFix64
		pub let amount: UFix64
		pub let bidder: Address
		pub let winning: Bool
		pub let confirmed: Bool

		init(id: UInt64, time: UFix64, amount: UFix64, bidder: Address, winning: Bool, confirmed: Bool) {
			self.id=id
			self.time=time
			self.amount=amount
			self.bidder=bidder
			self.winning=winning
			self.confirmed=confirmed
		}
	}

	pub struct BidInfo {
		access(contract) let id: UInt64
		access(contract) let vaultCap: Capability<&{FungibleToken.Receiver}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) var time: UFix64
		access(contract) var balance: UFix64
		access(contract) var winning: Bool


		init(id: UInt64, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultCap: Capability<&{FungibleToken.Receiver}>, time: UFix64, balance: UFix64) {
			self.id=id
			self.nftCap= nftCap
			self.vaultCap=vaultCap
			self.time=time
			self.balance=balance
			self.winning=false
		}

		pub fun increaseBid(_ amount:UFix64) {
			self.balance=self.balance+amount
			self.time=Clock.time()
		}

		access(contract) fun  withdraw(_ amount: UFix64) {
			self.balance=self.balance - amount
		}

		pub fun setWinning(_ value: Bool) {
			self.winning=value
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

		//this has to be an array I think, since we need ordering. 
		access(contract) let ticks: [Tick]

		access(contract) let auctionStatus: {UFix64: TickStatus}
		access(contract) var currentTickIndex: UInt64

		//this is a lookup table for the bid
		access(contract) let bidInfo: {UInt64: BidInfo}

		access(contract) let winningBids: [UInt64]

		//this is a table of ticks to ordered list of bid ids
		access(contract) let bids: {UFix64: [UInt64]}

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
			self.currentTickIndex=0
			self.numberOfItems=nfts.length
			self.ticks=ticks
			self.auctionStatus={}
			self.winningBids=[]
			//create the ticks
			self.nfts <- nfts
			self.winningBid=nil
			var emptyBids : {UFix64: [UInt64]}={}
			for tick in ticks {
				emptyBids[tick.startedAt]=[]
			}
			self.bids = emptyBids
			self.bidInfo= {}
			self.escrow <- {}
			self.ownerVaultCap=ownerVaultCap
			self.ownerNFTCap=ownerNFTCap
			self.royaltyVaultCap=royaltyVaultCap
			self.royaltyPercentage=royaltyPercentage
		}

		pub fun startAt() : UFix64 {
			return self.ticks[0].startedAt
		}

		access(contract) fun fullfill() {
			if self.winningBid== nil {
				Debug.log("Winning price is not set")
				panic("Cannot fullfill is not finished")
			}

			let nftIds= self.nfts.keys

			for id in self.winningBids {
				let bid= self.bidInfo[id]!
				if let vault <- self.escrow[bid.id] <- nil {
					if vault.balance > self.winningBid! {
						self.ownerVaultCap.borrow()!.deposit(from: <- vault.withdraw(amount: vault.balance-self.winningBid!))
					}
					if self.royaltyPercentage != 0.0 {
						self.royaltyVaultCap.borrow()!.deposit(from: <- vault.withdraw(amount: vault.balance*self.royaltyPercentage))
					}

					self.ownerVaultCap.borrow()!.deposit(from: <- vault)

					let nftId=nftIds.removeFirst()
					if let nft <- self.nfts[nftId] <- nil {
						//TODO: here we might consider adding the nftId that you have won to BidInfo and let the user pull it out
						self.bidInfo[bid.id]!.nftCap.borrow()!.deposit(token: <- nft)
					}
				}
			}
			/*
			//let just return all other money here and fix the issue with gas later
			//this will blow the gas limit on high number of bids
			for tick in self.ticks {
				if let bids=self.bids[tick.startedAt]{
					for bidId in bids {
						let bid= self.bidInfo[bidId]!
						if let vault <- self.escrow[bidId] <- nil {
							//TODO: check that it is still linked
							bid.vaultCap.borrow()!.deposit(from: <- vault)		
						}
					}
				}
			}
			*/

			emit AuctionDutchSettle(price: self.winningBid!, auction: self.uuid)
		}

		pub fun getBids() : Bids {
			var bids: [BidReport] =[]
			var numberWinning=0
			var winningBid=self.winningBid
			for tick in self.ticks {
				let localBids=self.bids[tick.startedAt]!
				for bid in localBids {
					let bidInfo= self.bidInfo[bid]!
					var winning=bidInfo.winning
					//we have an ongoing auction
					if self.winningBid == nil && numberWinning != self.numberOfItems {
						winning=true
						numberWinning=numberWinning+1
						if numberWinning== self.numberOfItems {
							winningBid=bidInfo.balance
						}
					}
					bids.append(BidReport(id: bid, time: bidInfo.time, amount: bidInfo.balance, bidder: bidInfo.vaultCap.address, winning: winning, confirmed:bidInfo.winning))
				}
			}
			return Bids(bids: bids, winningPrice: winningBid)
		}

		pub fun findWinners() : [UInt64] {

			var bids: [UInt64] =[]
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

		//this should be called something else
		pub fun isAuctionFinished() : Bool {

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

			let previousAcceptedBids=self.winningBids.length
			var winning=true
			for bid in bids {

				let bidInfo= self.bidInfo[bid]!
				//we do not have enough winning bids so we add this bid as a winning bid
				if self.winningBids.length < self.numberOfItems {
					self.winningBids.append(bid)
					//if we now have enough bids we need to set the winning bid
					if self.winningBids.length == self.numberOfItems {
						self.winningBid=bidInfo.balance
					}
				}

				Debug.log("Processing bid ".concat(bid.toString()).concat(" total accepted bids are ").concat(self.winningBids.length.toString()))

				self.bidInfo[bid]!.setWinning(winning)

				if self.winningBids.length == self.numberOfItems {
					winning=false
				} 
			}

			//lets advance the tick
			self.currentTickIndex=self.currentTickIndex+1

			if self.winningBids.length == self.numberOfItems {
				//this could be done later, but i will just do it here for ease of reading
				self.auctionStatus[tick.startedAt] = TickStatus(price:tick.price, startedAt: tick.startedAt, acceptedBids: self.numberOfItems - previousAcceptedBids, cumulativeAcceptedBids: self.numberOfItems)
				log(self.auctionStatus)
				return true
			}

			self.auctionStatus[tick.startedAt] = TickStatus(price:tick.price, startedAt: tick.startedAt, acceptedBids: bids.length, cumulativeAcceptedBids: self.winningBids.length)
			log(self.auctionStatus)
			return false
		}

		pub fun isLastTick() : Bool {
			let tickLength = UInt64(self.ticks.length-1)
			return self.currentTickIndex==tickLength
		}

		// taken from bisect_right in  pthon https://stackoverflow.com/questions/2945017/javas-equivalent-to-bisect-in-python
		pub fun bisect(items: [UInt64], new: BidInfo) : Int {
			var high=items.length
			var low=0
			while low < high {
				let mid =(low+high)/2
				let midBidId=items[mid]
				let midBid=self.bidInfo[midBidId]!
				if midBid.balance < new.balance || midBid.balance==new.balance && midBid.id > new.id {
					high=mid
				} else {
					low=mid+1
				}
			}
			return low
		}




		//this will not work well with cancelling of bids or increasing bids. I am thinking just add to tick array and sort it.
		priv fun insertBid(_ bid: BidInfo) {
			for tick in self.ticks {
				if tick.price > bid.balance {
					continue
				}

				//add the bid to the lookup table
				self.bidInfo[bid.id]=bid

				let bucket= self.bids[tick.startedAt]!
				//find the index of the new bid in the ordred bucket bid list
				let index= self.bisect(items:bucket, new: bid)

				//insert bid and mutate state
				bucket.insert(at: index, bid.id)
				self.bids[tick.startedAt]= bucket

				emit AuctionDutchBid(amount: bid.balance, bidder: bid.nftCap.address, auction: self.uuid, bid: bid.id)
				return 
			}
		}

		pub fun findTickForBid(_ id:UInt64) : Tick {
			for tick in self.ticks {
				let bucket= self.bids[tick.startedAt]!
				if bucket.contains(id) { 
					return tick
				}
			}
			panic("Could not find bid")
		}

		pub fun removeBidFromTick(_ id:UInt64, tick: UFix64) {
			//test om bisect vil funke her?
			var index=0
			let bids= self.bids[tick]!
			while index < bids.length {
				if bids[index] == id {
					bids.remove(at: index)
					self.bids[tick]=bids
					return
				}
				index=index+1
			}
		}

		access(contract) fun  cancelBid(id: UInt64) {
			//todo: pre that the bid exist and escrow exist
			//TODO: pre check that the bid has not been accepted already, that the tick has passed
			//let bid= self.b
			let bidInfo=self.bidInfo[id]!
			if let escrowVault <- self.escrow[id] <- nil {
				bidInfo.vaultCap.borrow()!.deposit(from: <- escrowVault)
				let oldTick=self.findTickForBid(id)
				self.removeBidFromTick(id, tick: oldTick.startedAt)
				self.bidInfo.remove(key: id)
			}
		}

		access(self) fun findTickForAmount(_ amount: UFix64) : Tick{
			for t in self.ticks {
				if t.price > amount {
					continue
				}
				return t
			}
			panic("Could not find tick for amount")
		}

		access(contract) fun getExcessBalance(_ id: UInt64) : UFix64 {
			let bid=self.bidInfo[id]!
			if self.winningBid != nil {
				//if we are done and you are a winning bid you will already have gotten your flow back in fullfillment
				if !bid.winning {
					return bid.balance
				}
			} else {
				if bid.balance > self.calculatePrice()  {
					return bid.balance - self.calculatePrice()
				}
			}
			return 0.0
		}

		access(contract) fun withdrawExcessFlow(id: UInt64, cap: Capability<&{FungibleToken.Receiver}>)  {
			let balance= self.getExcessBalance(id)
			if balance == 0.0 {
				return
			}

			let bid=self.bidInfo[id]!
			if let escrowVault <- self.escrow[id] <- nil {
				bid.withdraw(balance)
				let withdrawVault= cap.borrow()!
				if escrowVault.balance == balance {
					withdrawVault.deposit(from: <- escrowVault)
				} else {
					let tmpVault <- escrowVault.withdraw(amount: balance)
					withdrawVault.deposit(from: <- tmpVault)
					let oldVault <- self.escrow[id] <- escrowVault
					destroy oldVault
				}
				self.bidInfo[id]=bid
			}
		}

		access(contract) fun getBidInfo(id: UInt64) : BidInfo {
			return self.bidInfo[id]!
		}

		access(contract) fun  increaseBid(id: UInt64, vault: @FlowToken.Vault) {
			//todo: pre that the bid exist and escrow exist
			//TODO: pre check that the bid has not been accepted already, that the tick has passed
			//let bid= self.b
			let bidInfo=self.bidInfo[id]!
			if let escrowVault <- self.escrow[id] <- nil {
				bidInfo.increaseBid(vault.balance)
				escrowVault.deposit(from: <- vault)
				self.bidInfo[id]=bidInfo
				let oldVault <- self.escrow[id] <- escrowVault
				destroy oldVault


				var tick=self.findTickForBid(id)
				self.removeBidFromTick(id, tick: tick.startedAt)
				if tick.price < bidInfo.balance {
					tick=self.findTickForAmount(bidInfo.balance)
				} 
				let bucket= self.bids[tick.startedAt]!
				//find the index of the new bid in the ordred bucket bid list
				let index= self.bisect(items:bucket, new: bidInfo)

				//insert bid and mutate state
				bucket.insert(at: index, bidInfo.id)
				self.bids[tick.startedAt]= bucket

				//todo do we need seperate bid for increase?
				emit AuctionDutchBidIncreased(amount: bidInfo.balance, bidder: bidInfo.nftCap.address, auction: self.uuid, bid: bidInfo.id)
			} else {
				destroy vault
				panic("Cannot get escrow")
			}
			//need to check if the bid is in the correct bucket now
			//emit event
		}

		pub fun addBid(vault: @FlowToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultCap: Capability<&{FungibleToken.Receiver}>, time: UFix64) : UInt64{

			let bidId=self.totalBids

			let bid=BidInfo(id: bidId, nftCap: nftCap, vaultCap:vaultCap, time: time, balance: vault.balance)
			self.insertBid(bid)
			let oldEscrow <- self.escrow[bidId] <- vault
			self.totalBids=self.totalBids+(1 as UInt64)			
			destroy oldEscrow
			return bid.id
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
		pub fun getIds() : [UInt64] 
		//TODO: can we just join these two?
		pub fun getStatus(_ id: UInt64) : AuctionDutchStatus
		pub fun getBids(_ id: UInt64) : Bids
		//these methods are only allowed to be called from within this contract, but we want to call them on another users resource
		access(contract) fun getAuction(_ id:UInt64) : &Auction
		access(contract) fun bid(id: UInt64, vault: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, nftCap: Capability<&{NonFungibleToken.Receiver}>) : @Bid
	}


	pub struct AuctionDutchStatus {

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

		pub fun getStatus(_ id: UInt64) : AuctionDutchStatus{
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


			return AuctionDutchStatus(status: status, 
			currentPrice: currentPrice,
			totalItems: item.numberOfItems, 
			acceptedBids: item.winningBids.length, 
			startTime: item.startAt(),
			tickStatus: item.auctionStatus,
			metadata:item.metadata)
		}

		pub fun getBids(_ id:UInt64) : Bids {
			pre {
				self.auctions[id] != nil: "auction doesn't exist"
			}

			let item= self.getAuction(id)
			return item.getBids()
		}

		access(contract) fun getAuction(_ id:UInt64) : &Auction {
			pre {
				self.auctions[id] != nil: "auction doesn't exist"
			}
			return &self.auctions[id] as &Auction
		}

		access(contract) fun bid(id: UInt64, vault: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, nftCap: Capability<&{NonFungibleToken.Receiver}>) : @Bid{
			//TODO: pre id should exist

			let time=Clock.time()
			let vault <- vault as! @FlowToken.Vault
			let auction=self.getAuction(id)

			let price=auction.calculatePrice()

			//the currentPrice is still higher then your bid, this is find we just add your bid to the correct tick bucket
			if price > vault.balance {
				let bidId =auction.addBid(vault: <- vault, nftCap:nftCap, vaultCap: vaultCap, time: time)
				return <- create Bid(capability: AuctionDutch.account.getCapability<&Collection{Public}>(AuctionDutch.CollectionPublicPath), auctionId: id, bidId: bidId)
			}

			let tooMuchCash=vault.balance - price
			//you sent in too much flow when you bid so we return some to you and add a valid accepted bid
			if tooMuchCash != 0.0 {
				vaultCap.borrow()!.deposit(from: <- vault.withdraw(amount: tooMuchCash))
			}

			let bidId=auction.addBid(vault: <- vault, nftCap:nftCap, vaultCap: vaultCap, time: time)
			return <- create Bid(capability: AuctionDutch.account.getCapability<&Collection{Public}>(AuctionDutch.CollectionPublicPath), auctionId: id, bidId: bidId)
		}

		pub fun tickOrFullfill(_ id:UInt64) {
			let time=Clock.time()
			let auction=self.getAuction(id)

			//TODO: look at inlineing this

			if !auction.isAuctionFinished() {
				let tick=auction.getTick()
				emit AuctionDutchTick(tickPrice: tick.price, acceptedBids: auction.winningBids.length, totalItems: auction.numberOfItems, tickTime: tick.startedAt, auction: id)
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

			emit AuctionDutchCreated(name: metadata["name"] ?? "Unknown name", artist: metadata["artist"] ?? "Unknown artist",  number: length, owner: ownerVaultCap.address, id: auction.uuid)

			let oldAuction <- self.auctions[auction.uuid] <- auction
			destroy oldAuction
		}

		destroy () {
			destroy self.auctions
		}

	}

	pub fun getBids(_ id: UInt64) : Bids {
		let account = AuctionDutch.account
		let cap=account.getCapability<&Collection{Public}>(self.CollectionPublicPath)
		if let collection = cap.borrow() {
			return collection.getBids(id)
		}
		panic("Could not find auction capability")
	}

	pub fun getAuctionDutch(_ id: UInt64) : AuctionDutchStatus? {
		let account = AuctionDutch.account
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

		pub fun getBidInfo() : BidInfo {
			return self.capability.borrow()!.getAuction(self.auctionId).getBidInfo(id: self.bidId)
		}

		pub fun getExcessBalance() : UFix64 {
			return self.capability.borrow()!.getAuction(self.auctionId).getExcessBalance(self.bidId)
		}

		pub fun increaseBid(vault: @FlowToken.Vault) {
			self.capability.borrow()!.getAuction(self.auctionId).increaseBid(id: self.bidId, vault: <- vault)
		}

		pub fun cancelBid() {
			self.capability.borrow()!.getAuction(self.auctionId).cancelBid(id: self.bidId)
		}

		pub fun withdrawExcessFlow(_ cap: Capability<&{FungibleToken.Receiver}>) {
			self.capability.borrow()!.getAuction(self.auctionId).withdrawExcessFlow(id: self.bidId, cap:cap)
		}
	}

	pub struct ExcessFlowReport {
		pub let id: UInt64
		pub let winning: Bool
		pub let excessAmount: UFix64


		init(id: UInt64, report: BidInfo, excessAmount: UFix64) {
			self.id=id
			self.winning=report.winning
			self.excessAmount=excessAmount
		}
	}

	pub resource interface BidCollectionPublic {
		pub fun bid(marketplace: Address, id: UInt64, vault: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, nftCap: Capability<&{NonFungibleToken.Receiver}>) 
		pub fun getIds() :[UInt64]
		pub fun getReport(_ id: UInt64) : ExcessFlowReport

	}

	pub resource BidCollection:BidCollectionPublic {

		access(contract) let bids : @{UInt64: Bid}

		init() {
			self.bids <- {}
		}

		pub fun getIds() : [UInt64] {
			return self.bids.keys
		}

		pub fun getReport(_ id: UInt64) : ExcessFlowReport {
			let bid=self.getBid(id)

			return ExcessFlowReport(id:id, report: bid.getBidInfo(), excessAmount: bid.getExcessBalance())
		}

		pub fun bid(marketplace: Address, id: UInt64, vault: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, nftCap: Capability<&{NonFungibleToken.Receiver}>)  {

			let dutchAuctionCap=getAccount(marketplace).getCapability<&AuctionDutch.Collection{AuctionDutch.Public}>(AuctionDutch.CollectionPublicPath)
			let bid <- dutchAuctionCap.borrow()!.bid(id: id, vault: <- vault, vaultCap: vaultCap, nftCap: nftCap)
			self.bids[bid.uuid] <-! bid
		}


		pub fun withdrawExcessFlow( id: UInt64, vaultCap: Capability<&{FungibleToken.Receiver}>) {
			let bid = self.getBid(id)
			bid.withdrawExcessFlow(vaultCap)
		}

		pub fun cancelBid(_ id: UInt64) {
			let bid = self.getBid(id)
			bid.cancelBid()
			destroy <- self.bids.remove(key: bid.uuid)
		}

		pub fun increaseBid(_ id: UInt64, vault: @FungibleToken.Vault) {
			let vault <- vault as! @FlowToken.Vault
			let bid = self.getBid(id)
			bid.increaseBid(vault: <- vault)
		}

		access(contract) fun getBid(_ id:UInt64) : &Bid {
			pre {
				self.bids[id] != nil: "bid doesn't exist"
			}
			return &self.bids[id] as &Bid
		}


		destroy() {
			destroy  self.bids
		}

	}

	pub fun createEmptyBidCollection() : @BidCollection {
		return <- create BidCollection()
	}

	init() {
		self.CollectionPublicPath= /public/versusAuctionDutchCollection
		self.CollectionStoragePath= /storage/versusAuctionDutchCollection

		self.BidCollectionPublicPath= /public/versusAuctionDutchBidCollection
		self.BidCollectionStoragePath= /storage/versusAuctionDutchBidCollection


		let account=self.account
		let collection <- create Collection()
		account.save(<-collection, to: AuctionDutch.CollectionStoragePath)
		account.link<&Collection{Public}>(AuctionDutch.CollectionPublicPath, target: AuctionDutch.CollectionStoragePath)

	}
}