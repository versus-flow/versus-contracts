// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: DemoToken Vault Balance = 100, NFT.id[1 - 10]
// Account 0x02: DemoToken Vault Balance = 200, No NFTs
// Account 0x03: DemoToken Vault Balance = 200, No NFTs
// Account 0x04: DemoToken Vault Balance = 200, No NFTs

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Rocks from 0xf3fcd2c1a78f5eee

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

pub fun main() {
    // get the accounts' public address objects
    let account1 = getAccount(0xe03daebed8ca0615)
    let account2 = getAccount(0x01cf0e2f2f715450)
    let account3 = getAccount(0x179b6b1cb6755e31)
    let account4 = getAccount(0xf3fcd2c1a78f5eee)

    // get the reference to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let account1ReceiverRef = account1.getCapability(/public/DemoTokenBalance)!
                                      .borrow<&{FungibleToken.Balance}>()
                                      ?? panic("could not borrow the vault balance reference for account 1")
    
    let account2ReceiverRef = account2.getCapability(/public/DemoTokenBalance)!
                                      .borrow<&{FungibleToken.Balance}>()
                                      ?? panic("could not borrow the vault balance reference for account 2")

    let account3ReceiverRef = account3.getCapability(/public/DemoTokenBalance)!
                                      .borrow<&{FungibleToken.Balance}>()
                                      ?? panic("could not borrow the vault balance reference for account 3")

    let account4ReceiverRef = account4.getCapability(/public/DemoTokenBalance)!
                                      .borrow<&{FungibleToken.Balance}>()
                                      ?? panic("could not borrow the vault balance reference for account 4")
    
    // log the Vault balance of both accounts
    // and ensure they are the correct numbers
    // Account 1 should have 100
    // Account 2 should have 200
    // Account 3 should have 200
    // Account 4 should have 200
    
    log(account1ReceiverRef.owner)
    log(account1ReceiverRef.balance)
    
    log(account2ReceiverRef.owner)
    log(account2ReceiverRef.balance)

    log(account3ReceiverRef.owner)
    log(account3ReceiverRef.balance)

    log(account4ReceiverRef.owner)
    log(account4ReceiverRef.balance)


    // verify that the balances are correct
    // if account3ReceiverRef.balance != UFix64(100) || account2ReceiverRef.balance != UFix64(200) || account1ReceiverRef.balance != UFix64(200) || account4ReceiverRef.balance != UFix64(200) {
    //     panic("Account balances are incorrect!")
    // }

     
    // find the public receiver capability for their Collections
    let account1NFTCapability = account1.getCapability(/public/RockCollection)!
    let account2NFTCapability = account2.getCapability(/public/RockCollection)!
    let account3NFTCapability = account3.getCapability(/public/RockCollection)!
    let account4NFTCapability = account4.getCapability(/public/RockCollection)!

    // borrow references from the capabilities
    let account1NFTRef = account1NFTCapability.borrow<&{NonFungibleToken.CollectionPublic}>()
                        ?? panic("unable to borrow a reference to NFT collection for Account 1")
    let account2NFTRef = account2NFTCapability.borrow<&{NonFungibleToken.CollectionPublic}>()
                        ?? panic("unable to borrow a reference to NFT collection for Account 2")
    let account3NFTRef = account3NFTCapability.borrow<&{NonFungibleToken.CollectionPublic}>()
                        ?? panic("unable to borrow a reference to NFT collection for Account 3")
    let account4NFTRef = account4NFTCapability.borrow<&{NonFungibleToken.CollectionPublic}>()
                        ?? panic("unable to borrow a reference to NFT collection for Account 4")

    // print both collections as arrays of ids
    log(account1NFTRef.owner)
    log(account1NFTRef.getIDs())
    
    log(account2NFTRef.owner)
    log(account2NFTRef.getIDs())
    
    log(account3NFTRef.owner)
    log(account3NFTRef.getIDs())
    
    log(account4NFTRef.owner)
    log(account4NFTRef.getIDs())

    // verify that the collections are correct
    // if account1NFTRef.getIDs().length == 0 || account2NFTRef.getIDs().length == 0 || account3NFTRef.getIDs().length != 0 || account4NFTRef.getIDs().length == 0 {
    //     log("A OK")
    // } else {
    //     log("Wrong NFT collection")
    // }
}
 