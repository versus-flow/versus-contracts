package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.TransactionFromFile("transfer_flow").
		SignProposeAndPayAsService().
		UFix64Argument("1000.0").
		AccountArgument("versus").
		RunPrintEventsFull()

	flow.TransactionFromFile("transfer_flow").
		SignProposeAndPayAsService().
		UFix64Argument("100.0").
		AccountArgument("admin").
		RunPrintEventsFull()

}
