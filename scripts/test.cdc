pub fun bubbleSort(_ list: [BidInfo]) : [BidInfo]{
	var changed=true
	while changed {
		changed=false
		var index=0
		while index < list.length-1 {
			var curr = list[index]
			var next= list[index+1]

			//the current item has lower price or same price and higher id.
			if curr.balance < next.balance || next.balance==curr.balance && curr.id > next.id {
				list[index]=next
				list[index+1]=curr
				changed=true
			}
			index=index+1
		}
	}
	return list
}

pub fun insertBid(items: [BidInfo], new: BidInfo) : [BidInfo]{

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

	let index= inner(items: items, new:new, lo:0, hi: items.length)
	items.insert(at: index, new)
	return items
}

pub struct BidInfo{

	pub let balance: UFix64
	pub let id: UInt64
	pub let desc:String

	init(balance:UFix64, id: UInt64, desc:String) {
		self.balance =balance
		self.id=id
		self.desc=desc
	}
}


pub fun main() {

	var bids :[BidInfo] = [BidInfo(balance: 1.0, id:2, desc:"1"), BidInfo(balance: 1.0, id:3, desc:"1"), BidInfo(balance: 0.9, id:4, desc:"1" )]

	log(bids)

	bids= insertBid(items: bids, new: BidInfo(balance: 1.0 , id:3, desc:"BOO"))
	log(bids)

}
