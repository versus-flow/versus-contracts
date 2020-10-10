package main

import (
	"fmt"

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

//NB! start from root dir with makefile
func main() {
	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.DeployContract("NonFungibleToken")
	flow.DeployContract("DemoToken")
	flow.DeployContract("Art")
	flow.DeployContract("Auction")
	flow.DeployContract("Versus")

	//We create the accounts and set up the stakeholdres in our scenario

	//Marketplace will own a marketplace and get a cut for each sale, this account does not own any NFT
	flow.CreateAccount("marketplace")
	flow.TransactionFromFile("setup/actor").
		SignProposeAndPayAs("marketplace").
		UFix64Argument("0.0").
		Run()
	fmt.Scanln()

	fmt.Println("MarketplaceCut: 15%, drop length: 5 ticks")

	flow.TransactionFromFile("setup/versus").
		SignProposeAndPayAs("marketplace").
		UFix64Argument("0.15").      //cut percentage,
		Argument(cadence.UInt64(5)). //drop length
		Argument(cadence.UInt64(5)). //minimumBlockRemainingAfterBidOrTie
		Run()

}
