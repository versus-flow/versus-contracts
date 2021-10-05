import Versus from "../contracts/Versus.cdc"

//This transaction will setup a drop in a versus auction
transaction(id: UInt64){
	let client: &Versus.Admin
	prepare(account: AuthAccount) {
		self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
	}

	execute {
		self.client.tickDutchAuction(id)
	}
}
