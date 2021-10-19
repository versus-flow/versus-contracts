package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

//NB! start from root dir with makefile
func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	/*
		flow.ScriptFromFile("dutchAuctionUserBid").AccountArgument("admin").Run()

		flow.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("admin").
			AccountArgument("versus").
			UInt64Argument(14302812). //id of auction
			UFix64Argument("10.00").  //amount to bid
			RunPrintEventsFull()

		flow.ScriptFromFile("dutchAuctionUserBid").AccountArgument("admin").Run()
	*/
	flow.TransactionFromFile("dutchBidCancel").
		SignProposeAndPayAs("admin").
		UInt64Argument(14310642). //id of bid
		RunPrintEventsFull()

}
