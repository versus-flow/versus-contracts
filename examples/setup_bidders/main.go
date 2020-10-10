package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const art = "Art"
const versus = "Versus"
const auction = "Auction"

const marketplace = "Marketplace"
const artist = "Artist"
const buyer1 = "Buyer1"
const buyer2 = "Buyer2"

func ufix(input string) cadence.UFix64 {
	amount, err := cadence.NewUFix64(input)
	if err != nil {
		panic(err)
	}
	return amount
}

func main() {
	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.CreateAccount("buyer1")
	flow.TransactionFromFile("setup/actor").SignProposeAndPayAs("buyer1").UFix64Argument("100.0").Run() //tokens to mint
}
