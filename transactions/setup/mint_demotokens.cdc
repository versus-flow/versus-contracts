// This transaction mints tokens for Accounts 1 and 2 using
// the minter stored on Account 1.

// Signer: Account 1 - 0x01cf0e2f2f715450

import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

transaction {

    // public Vault reciever references for both accounts
    let acct1Ref: &{FungibleToken.Receiver}
    let acct2Ref: &{FungibleToken.Receiver}
    let acct3Ref: &{FungibleToken.Receiver}
    let acct4Ref: &{FungibleToken.Receiver}

    // reference to the DemoToken administrator
    let adminRef: &DemoToken.Administrator
    let minterRef: &DemoToken.Minter
    
    prepare(acct: AuthAccount) {
        // get the public object for Account 2
        let account2 = getAccount(0xf3fcd2c1a78f5eee)
        let account3 = getAccount(0xe03daebed8ca0615)
        let account4 = getAccount(0x01cf0e2f2f715450)

        // retreive the public vault references for both accounts
        self.acct1Ref = acct.getCapability(/public/DemoTokenReceiver)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Could not borrow owner's vault reference")
                        
        self.acct2Ref = account2.getCapability(/public/DemoTokenReceiver)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Could not borrow Account 2's vault reference")
        
        self.acct3Ref = account3.getCapability(/public/DemoTokenReceiver)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Could not borrow Account 3's vault reference")

        self.acct4Ref = account4.getCapability(/public/DemoTokenReceiver)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Could not borrow Account 4's vault reference")
        
        // borrow a reference to the Administrator resource in Account 2
        self.adminRef = acct.borrow<&DemoToken.Administrator>(from: /storage/DemoTokenAdmin)
                            ?? panic("Signer is not the token admin!")
        
        // create a new minter and store it in account storage
        let minter <-self.adminRef.createNewMinter(allowedAmount: UFix64(1000))
        acct.save<@DemoToken.Minter>(<-minter, to: /storage/DemoTokenMinter)

        // create a capability for the new minter
        let minterRef = acct.link<&DemoToken.Minter>(
            /public/DemoTokenMinter,
            target: /storage/DemoTokenMinter
        )

        // get the stored Minter reference from account 2
        self.minterRef = acct.borrow<&DemoToken.Minter>(from: /storage/DemoTokenMinter)
            ?? panic("Could not borrow owner's vault minter reference")
    }

    execute {
        // mint tokens for both accounts
        self.acct1Ref.deposit(from: <-self.minterRef.mintTokens(amount: UFix64(100)))
        self.acct2Ref.deposit(from: <-self.minterRef.mintTokens(amount: UFix64(200)))
        self.acct3Ref.deposit(from: <-self.minterRef.mintTokens(amount: UFix64(200)))
        self.acct4Ref.deposit(from: <-self.minterRef.mintTokens(amount: UFix64(200)))

        log("Minted new DemoTokens for all accounts")
    }
}
 