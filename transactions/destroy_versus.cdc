import Versus from "../../contracts/Versus.cdc"
//This transaction will destroy a versus drop
transaction(id: UInt64) {
    let versus: &Versus.DropCollection

    prepare(account: AuthAccount) {
        self.versus= account.borrow<&Versus.DropCollection>(from: Versus.CollectionStoragePath)!
    }
    
    execute {
        let drop <- self.versus.drops[id] <- nil
        destroy drop

    }
}

