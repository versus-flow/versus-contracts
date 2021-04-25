package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

//NB! start from root dir with makefile
func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.CreateAccount("marketplace", "artist", "buyer1", "buyer2")

	flow.TransactionFromFile("unlink_flow").SignProposeAndPayAs("buyer1").RunPrintEventsFull()
	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer1").UFix64Argument("1000.0").RunPrintEventsFull()
}
