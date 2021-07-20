//mainnnet
import Versus from 0xd796ff17107bbff6

/*
  This script will check if an address has created an admin client
 */
pub fun main(account:Address) : Bool {
    return getAccount(account).getCapability<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath).check()
}
 
 
 
