// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: DemoToken Vault Balance = 1050, No NFTs
// Account 0x02: DemoToken Vault Balance = 10, NFT.id = 1

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
    let account1 = getAccount(0x01cf0e2f2f715450)
    let account2 = getAccount(0x179b6b1cb6755e31)

    // get the reference to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let account1ReceiverRef = account1.getCapability(/public/DemoTokenBalance)!
                                      .borrow<&DemoToken.Vault{FungibleToken.Balance}>()
                                      ?? panic("could not borrow the vault balance reference for account 1")
    
    let account2ReceiverRef = account2.getCapability(/public/DemoTokenBalance)!
                                      .borrow<&DemoToken.Vault{FungibleToken.Balance}>()
                                      ?? panic("could not borrow the vault balance reference for account 2")
    
    // log the Vault balance of both accounts
    // and ensure they are the correct numbers
    // Account 1 should have 40
    // Account 2 should have 20
    log("Account 1 DemoToken Balance:")
    log(account1ReceiverRef.balance)
    
    log("Account 2 DemoToken Balance:")
    log(account2ReceiverRef.balance)


    // verify that the balances are correct
    if account1ReceiverRef.balance != UFix64(1050) || account2ReceiverRef.balance != UFix64(10) {
        panic("Account balances are incorrect!")
    }

    // find the public receiver capability for their Collections
    let account1NFTCapability = account1.getCapability(/public/RockCollection)!
    let account2NFTCapability = account2.getCapability(/public/RockCollection)!

    // borrow references from the capabilities
    let account1NFTRef = account1NFTCapability.borrow<&{NonFungibleToken.CollectionPublic}>()
                        ?? panic("unable to borrow a reference to NFT collection for Account 1")
    let account2NFTRef = account2NFTCapability.borrow<&{NonFungibleToken.CollectionPublic}>()
                        ?? panic("unable to borrow a reference to NFT collection for Account 2")

    // print both collections as arrays of ids
    log("Account 1 NFT IDs")
    log(account1NFTRef.getIDs())
    
    log("Account 2 NFT IDs")
    log(account2NFTRef.getIDs())

    // verify that the collections are correct
    if account1NFTRef.getIDs().length != 0 || account2NFTRef.getIDs()[0] != UInt64(1) {
        panic("Wrong NFT Collections!")
    }
}
