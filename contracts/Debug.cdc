pub contract Debug {

	pub event Log(msg: String)
	
	access(account) var enabled :Bool

	pub fun log(_ msg: String) {
		if self.enabled {
			emit Log(msg: msg)
		}
	}

	access(account) fun enable() {
		self.enabled=true
	}

	init() {
		self.enabled=false
	}


}
