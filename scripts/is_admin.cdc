import Versus from "../contracts/Versus.cdc"
/*
  This script will check an address and print out its an admin
 *
pub fun main(address:Address) : Bool {

    let account=getAccount(address)
    let adminClient: Capability<&{Versus.AdminPublic}> =account.getCapability<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath) 
    return adminClient.check()

}
