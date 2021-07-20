package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.TransactionFromFile("mint_edition").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0x1ad314a2f884cd63").
		RawAccountArgument("0x886f3aeaf848c535").
		UInt64Argument(46).
		UInt64Argument(0).
		UInt64Argument(32).
		RunPrintEventsFull()

}
