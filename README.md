# Flow Auction Contract

A composable auction contract with a custom fungible and non-fungible token for testing. Both tokens conform to the token standards found in the Flow repo: [FT](https://github.com/onflow/flow-ft/blob/master/contracts/FungibleToken.cdc) | [NFT](https://github.com/onflow/flow-nft/blob/master/contracts/NonFungibleToken.cdc)

## Deployment

This demo is currently available for download and deployment with the Flow CLI and VS Code Extension

### Go Tooling Deployment (Recommended)

1. Ensure Go is [installed on your machine](https://golang.org/dl/) `recommended version 1.13^`
2. [Install the Flow CLI](https://docs.onflow.org/docs/cli) and VS Code Extension
3. Run `$ git clone https://github.com/0xAlchemist/votey-auction` in a terminal window
4. Change to the project directory `cd votey-auction`
5. Rename `flow.sample.json` to `flow.json`: `$ mv flow.sample.json flow.json`
6. Run `$ go run run.go`

