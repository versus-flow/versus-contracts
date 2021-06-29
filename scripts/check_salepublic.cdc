import Marketplace, Art from 0xf8d6e0586b0a20c7
/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(owner:Address, id: UInt64) {
   
    let account= getAccount(owner)
    let marketplaceCap = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)

    let marketplace= marketplaceCap.borrow()!
    let art=marketplace.listSaleItems()

    log(art)
}
 
 
 
