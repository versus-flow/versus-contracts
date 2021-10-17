import TopShot from 0x877931736ee77cff

pub fun main(address: Address): Bool {
    let account = getAccount(address)
    return account.getCapability<&{TopShot.MomentCollectionPublic}>(/public/MomentCollection).check()
}
