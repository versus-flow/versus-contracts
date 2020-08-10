// This transaction sets up Account 1 for the votey-auction 
// by publishing a Vault reference and creating an empty NFT Collection

// Signer: Account 1 - 0x01cf0e2f2f715450

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Rocks from 0xf3fcd2c1a78f5eee

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc
transaction {

    prepare(acct: AuthAccount) {
        // Create a public receiver capability to the Vault
        acct.link<&DemoToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(
            /public/DemoTokenReceiver,
            target: /storage/DemoTokenVault
        )

        log("Created vault references")
        
        // store an empty NFT Collection in account storage
        acct.save<@NonFungibleToken.Collection>(<-Rocks.createEmptyCollection(), to: /storage/RockCollection)

        // publish a capability to the Collection in storage
        acct.link<&{Rocks.PublicCollectionMethods}>(/public/RockCollection, target: /storage/RockCollection)

        log("Created a new empty collection and published a reference")
    }
}
 