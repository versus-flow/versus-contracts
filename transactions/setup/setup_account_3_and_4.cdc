// This transaction adds an empty Vault
// and Rock Collection to Account 3


// Signer: Account 3 - 0xf3fcd2c1a78f5eee

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Rocks from 0xf3fcd2c1a78f5eee

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

transaction{
    
    prepare(acct: AuthAccount) {
        
        // create a new empty Vault resource
        let vaultA <- DemoToken.createEmptyVault()

        // store the vault in the account storage
        acct.save<@FungibleToken.Vault>(<-vaultA, to: /storage/DemoTokenVault)

        // create a public Receiver capability to the Vault
        acct.link<&DemoToken.Vault{FungibleToken.Receiver}>(
            /public/DemoTokenReceiver,
            target: /storage/DemoTokenVault
        )

        // create a public Balance capability to the Vault
        acct.link<&DemoToken.Vault{FungibleToken.Balance}>(
            /public/DemoTokenBalance,
            target: /storage/DemoTokenVault
        )

        log("Created a Vault and published the references")
        
        // create a new empty Rock Collection
        let NFTCollecton <- Rocks.createEmptyCollection()

        // store the Collection in account storage
        acct.save<@NonFungibleToken.Collection>(<-NFTCollecton, to: /storage/RockCollection)

        // create a public CollectionPublic capability to the Rock Collection
        acct.link<&{Rocks.PublicCollectionMethods}>(
            /public/RockCollection,
            target: /storage/RockCollection
        )


        log("Created a Rock Collection and published the references")

        log("Account is ready to Rock!")        
    }
}
 