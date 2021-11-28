import Versus from "../contracts/Versus.cdc"

//Transaction to mint Art and edition art and deploy to all addresses
transaction() {
	let client: &Versus.Admin

	prepare(account: AuthAccount) {
		self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
	}

	execute {
		self.client.getFlowWallet()
		return true
	}
}

