// This transaction uses the signers Vault tokens to purchase an NFT
// from the Sale collection of account 1.

// Signer - Account 2 - 0x179b6b1cb6755e31

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import Marketplace from 0xe03daebed8ca0615

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

transaction {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT
    let collectionRef: &AnyResource{NonFungibleToken.Receiver}

    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {
        // get the references to the buyer's Vault and NFT Collection receiver
        self.collectionRef = account.borrow<&AnyResource{NonFungibleToken.Receiver}>(from: /storage/RockCollection)!
        let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/DemoTokenVault)
            ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 10.0)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(0x01cf0e2f2f715450)

        // get the reference to the seller's sale
        let saleRef = seller.getCapability(/public/NFTSale)!
                         .borrow<&AnyResource{Marketplace.SalePublic}>()
                         ?? panic("Could not borrow seller's sale reference")

        // purchase the NFT the seller is selling, giving them the reference
        // to your NFT collection and giving them the tokens to buy it
        saleRef.purchase(tokenID: UInt64(1), recipient: self.collectionRef, buyTokens: <-self.temporaryVault)

        log("Token ID 1 has been bought by account 2")
    }
}
 