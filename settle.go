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

	// Setup DemoToken account with an NFT Collection and an Auction Collection
	flow.SendTransaction("buy/settle", demoToken)

}
