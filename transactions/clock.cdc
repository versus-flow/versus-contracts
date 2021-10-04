import Versus from "../contracts/Versus.cdc"

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient:  &Versus.Admin = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
		adminClient.advanceClock(clock)

	}
}
