// This transaction creates an empty NFT Collection for the signer
// and publishes a capability to the collection in storage

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Rocks from 0xf3fcd2c1a78f5eee

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - DemoToken.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - Rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - Auction.cdc
transaction {

    prepare(acct: AuthAccount) {
        // store an empty NFT Collection in account storage
        acct.save<@NonFungibleToken.Collection>(<-Rocks.createEmptyCollection(), to: /storage/RockCollection)

        // publish a capability to the Collection in storage
        acct.link<&{NonFungibleToken.CollectionPublic}>(/public/RockCollection, target: /storage/RockCollection)

        log("Created a new empty collection and published a reference")
    }
}
 