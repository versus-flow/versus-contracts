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

pub struct BidInfo{

	pub let balance: UFix64
	pub let id: UInt64

	init(balance:UFix64, id: UInt64) {
		self.balance =balance
		self.id=id
	}
}
pub fun main() {


	var bids :[BidInfo] = [BidInfo(balance: 0.9, id:3), BidInfo(balance: 1.0, id:2), BidInfo(balance: 0.9, id:1 )]
	log(bids)

	bids=bubbleSort(bids)
	log(bids)

}
