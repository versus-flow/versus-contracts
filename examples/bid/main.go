package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {
	auctionID := 1
	amount := "10.01"
	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.TransactionFromFile("buy/bid").
		SignProposeAndPayAs("buyer1").
		AccountArgument("marketplace").
		Argument(cadence.UInt64(1)).         //id of drop
		Argument(cadence.UInt64(auctionID)). //id of auction to bid on
		UFix64Argument(amount).              //amount to bid
		Run()
}
