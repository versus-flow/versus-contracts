// This transaction adds an empty Vault to Account 2
// and mints new NFTs which are deposited into
// the NFT collection on Account 1.

// Signer: Account 2 - 0x179b6b1cb6755e31

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

    // private reference to this account's minter resource
    let minterRef: &Rocks.NFTMinter
    
    prepare(acct: AuthAccount) {
        // borrow a reference to the NFTMinter in storage
        self.minterRef = acct.borrow<&Rocks.NFTMinter>(from: /storage/RockMinter)
            ?? panic("Could not borrow owner's vault minter reference")
        
    }

    execute {
        // Get the recipient's public account object
        let recipient = getAccount(0x179b6b1cb6755e31)

        // get the collection reference for the receiver
        // getting the public capability and borrowing the reference from it
        let receiverCap = recipient.getCapability(/public/RockCollection)!

        let receiverRef = receiverCap.borrow<&{Rocks.PublicCollectionMethods}>()
                                   ?? panic("unable to borrow nft receiver reference")

        // mint an NFT and deposit it in the receiver's collection
        let amountNFTs = 10
        var counter = 0

        while counter < amountNFTs {
            self.minterRef.mintNFT(recipient: receiverRef)
            counter = counter + 1
            
        }

        log("New NFT(s) minted for account 1")
    }
}
 