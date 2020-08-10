# Flow Auction Contract

A composable auction contract with a custom fungible and non-fungible token for testing. Both tokens conform to the token standards found in the Flow repo: [FT](https://github.com/onflow/flow-ft/blob/master/contracts/FungibleToken.cdc) | [NFT](https://github.com/onflow/flow-nft/blob/master/contracts/NonFungibleToken.cdc)

## Deployment

This demo is currently available for download and deployment with the Flow CLI and VS Code Extension

### VS Code Deployment Instructions

1. Start the Flow Emulator and ensure you have 4 accounts created
2. Switch to `account 4 (0xe03daebed8ca0615)` and deploy `onflow/NonFungibleToken.cdc`
3. Switch to `account 1 (0x01cf0e2f2f715450)` and deploy `demo-token.cdc`
4. Switch to `account 2 (0x179b6b1cb6755e31)` and deploy `rocks.cdc`
5. Switch to `account 3 (0xf3fcd2c1a78f5eee)` and deploy `votey-auction.cdc`

## Account Setup

1. Send `transactions/setup/setup_account_1.cdc` with `account 1` selected as the signer
    - This transaction:
        - publishes a reference to the signer's DemoToken Vault
        - creates and stores a new NFT Collection
        - publishes a reference to the new NFT Collection
2. Send `transactions/setup/setup_account_2.cdc` with `account 2` selected as the signer
    - This transaction:
        - creates an stores an empty DemoToken Vault
        - publishes separate references to the vault Receiver and Balance interfaces
        - mints a new NFT (ID: 1) and deposits it into `account 1`'s NFT Collection
3. Send `transactions/setup/setup_account_1_tx_minting.cdc` with `account 1` selected as the signer
    - This transaction:
        - creates a new DemoToken minter with an allowedAmount of 1000
        - mints and deposits 40 DemoTokens into `account 1`'s Vault
        - mints and deposits 20 DemoTokens into `account 2`'s Vault
4. Send `transactions/setup/setup_account_3_and_4.cdc` with `account 3` and `account 4` selected as the signer
    - This transaction:
        - creates an stores an empty DemoToken Vault
        - publishes separate references to the vault Receiver and Balance interfaces 
5. Run `scripts/check_setup.cdc` to check the account balances are correct
    - `account 1` should have 100 DemoTokens and 10 NFT 
    - `account 2, 3, 4` should have 200 DemoTokens and no NFTs

Example `scripts/check_setup.cdc` response:

```bash
DEBU[0782] LOG [5175e9] "Account 1 DemoToken Balance:" 
DEBU[0782] LOG [5175e9] 100.00000000 
DEBU[0782] LOG [5175e9] "Account 2 DemoToken Balance:" 
DEBU[0782] LOG [5175e9] 200.00000000 
DEBU[0782] LOG [5175e9] "Account 3 DemoToken Balance:" 
DEBU[0782] LOG [5175e9] 200.00000000 
DEBU[0782] LOG [5175e9] "Account 4 DemoToken Balance:" 
DEBU[0782] LOG [5175e9] 200.00000000 
DEBU[0782] LOG [5175e9] "Account 1 NFT IDs" 
DEBU[0782] LOG [5175e9] [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] 
DEBU[0782] LOG [5175e9] "Account 2 NFT IDs" 
DEBU[0782] LOG [5175e9] []           
DEBU[0782] LOG [5175e9] "Account 3 NFT IDs" 
DEBU[0782] LOG [5175e9] []           
DEBU[0782] LOG [5175e9] "Account 4 NFT IDs" 
DEBU[0782] LOG [5175e9] []        
```

## List a Token For Sale

1. Send `transactions/list/list_token_account_1.cdc` with `account 1` selected as the signer
    - This transaction:
        - creates a new SaleCollection
        - withdraw's NFT.id: 1
        - places NFT.id: 1 in the SaleCollection with a price of 10 DemoTokens
        - publishes a reference to the SaleCollection's SalePublic interface
2. Run `transactions/list/start_auction_account_1.cdc` with `account 1` selected as the signer
    - This transaction:
        - start the auction
3. Run `scripts/check_sales_account_1.cdc` to check for active NFT sales
    - `account 1` should have ten NFT (ID: 1) in the queue for a price of 10 DemoTokens
Example `scripts/check_sales_account_1.cdc` response:

```bash
DEBU[0866] LOG [4a2468] "Account 1 NFTs in the auction queue" 
DEBU[0866] LOG [4a2468] {0: 10.00000000, 1: 10.00000000, 2: 10.00000000, 3: 10.00000000, 4: 10.00000000, 5: 10.00000000, 6: 10.00000000, 7: 10.00000000, 8: 10.00000000, 9: 10.00000000}  
```

## Purchase a Token

1. Send `transactions/buy/purchase_nft_account_2.cdc` with `account 2` selected as the signer
    - This transaction:
        - withdraws 10 DemoTokens from the `account 2`'s Vault
        - purchases the NFT from `account 1` for 10 DemoTokens
        - deposits the NFT into `account 2`'s NFT Collection

2. Run `scripts/check_after_nft_purchase.cdc` to check the updated account balances
    - `account 1` should have 1050 DemoTokens and no NFTs
    - `account 2` should have 10 DemoTokens and 1 NFT (ID: 1)

Example `scripts/check_after_nft_purchase.cdc` response:

```bash
DEBU[0363] LOG [8f886c] "Account 1 DemoToken Balance:"
DEBU[0363] LOG [8f886c] 1050.00000000
DEBU[0363] LOG [8f886c] "Account 2 DemoToken Balance:"
DEBU[0363] LOG [8f886c] 10.00000000  
DEBU[0363] LOG [8f886c] "Account 1 NFT IDs"
DEBU[0363] LOG [8f886c] []
DEBU[0363] LOG [8f886c] "Account 2 NFT IDs"
DEBU[0363] LOG [8f886c] [1]
```
 
