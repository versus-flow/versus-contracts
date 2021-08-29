import Versus from "../contracts/Versus.cdc"
//This transaction will destroy a versus drop using the admin client
transaction(id: UInt64) {
	let client: &Versus.Admin
	prepare(account: AuthAccount) {
		self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
	}

	execute {
		let dropCollection=self.client.getDropCollection()
		let drop <- dropCollection.drops[id]  <- nil
		destroy drop
	}
}

