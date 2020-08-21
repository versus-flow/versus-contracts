
//This transaction setup of a versus marketplace
//Each drop settlement will deposit cutPercentage number of tokens into the signers vault
//Standard dropLength can be set and the number of blocks to postpone the drops on if there is a late bid

// If there is a bid 1 block before it ends it will be extended with minimumBlockRemainingAfterBidOrTie-1 

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Art from 0xf3fcd2c1a78f5eee
import Auction from 0xe03daebed8ca0615
import Versus from 0x045a1763c93006ca

transaction(cutPercentage: UFix64, dropLength: UInt64, minimumBlockRemainingAfterBidOrTie: UInt64) {

    prepare(account: AuthAccount) {
        // create a new sale object     
        // initializing it with the reference to the owner's Vault


        // Would this fail if the capability was not here? 
        let marketplaceReceiver=account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!
        if !marketplaceReceiver.check() {
            panic("Cannot borrow vault receiver run the setup/actor transaction first")
        }

         let marketplaceNFTTrash=account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/ArtCollection)!

        let versus <- Versus.createVersusDropCollection(
            marketplaceVault: marketplaceReceiver,
            marketplaceNFTTrash:marketplaceNFTTrash,
            cutPercentage: cutPercentage,
            dropLength: dropLength, 
            minimumBlockRemainingAfterBidOrTie: minimumBlockRemainingAfterBidOrTie
        )

        // store the sale resource in the account for storage
        account.save(<-versus, to: /storage/Versus)

        // create a public capability to the sale so that others
        // can call it's methods
        account.link<&{Versus.PublicDrop}>(
            /public/Versus,
            target: /storage/Versus
        )

        log("Versus collection and public capability created created.")
    }
}
 