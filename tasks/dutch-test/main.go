package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

//NB! start from root dir with makefile
func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	/*
		flow.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("versus").
			AccountArgument("versus").
			UInt64Argument(14349706). //id of auction
			UFix64Argument("9.00").   //amount to bid
			RunPrintEventsFull()

		flow.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("versus").
			AccountArgument("versus").
			UInt64Argument(14349706). //id of auction
			UFix64Argument("9.00").   //amount to bid
			RunPrintEventsFull()
	*/

	flow.ScriptFromFile("dutchAuctionUserBid").AccountArgument("versus").Run()

	/*
		flow.TransactionFromFile("dutchBidCancel").
			SignProposeAndPayAs("versus").
			UInt64Argument(14349744). //id of bid
			RunPrintEventsFull()

		/*

			flow.TransactionFromFile("dutchBidIncrease").
				SignProposeAndPayAs("admin").
				UInt64Argument(14310642). //id of bid
				UFix64Argument("10.0").   //id of bid
				RunPrintEventsFull()
	*/

}
