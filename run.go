package main

import (
	"github.com/0xAlchemist/go-flow-tooling/tooling"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const rocks = "Rocks"
const auction = "Auction"

func main() {
	flow := tooling.NewFlowConfigLocalhost()

	flow.DeployContract(nonFungibleToken)
	flow.DeployContract(demoToken)
	flow.DeployContract(rocks)
	flow.DeployContract(auction)

	// Setup DemoToken account with an NFT Collection and an Auction Collection
	flow.SendTransaction("setup/create_nft_collection", demoToken)
	flow.SendTransaction("setup/create_auction_collection", demoToken)

	// Setup Rocks account with DemoToken Vault
	flow.SendTransaction("setup/create_demotoken_vault", rocks)

	// Setup Auction Account with empty DemoToken Vault and Rock Collection
	flow.SendTransaction("setup/create_demotoken_vault", auction)
	flow.SendTransaction("setup/create_nft_collection", auction)

	// Setup NonFungibleToken Account with empty DemoToken Vault and Rock Collection
	flow.SendTransaction("setup/create_demotoken_vault", nonFungibleToken)
	flow.SendTransaction("setup/create_nft_collection", nonFungibleToken)

	// Mint DemoTokens for each account
	flow.SendTransaction("setup/mint_nfts", rocks)
	flow.SendTransaction("setup/mint_demotokens", demoToken)

	// Check the balances are properly setup for the auction demo
	flow.RunScript("check_setup")

	// Add NFTs to the Auction collection for the DemoToken account
	flow.SendTransaction("list/add_nfts_to_auction", demoToken)

	// Check the auction sale data for the DemoToken account (hardcoded for now)
	flow.RunScript("check_sales_listings")
}
