package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	//create the AdminPublicAndSomeOtherCollections
	flow.TransactionFromFile("setup/versus1_testnet").
		SignProposeAndPayAs("admin").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("setup/versus2_testnet").
		SignProposeAndPayAs("versus").
		AccountArgument("admin").
		RunPrintEventsFull()

}
