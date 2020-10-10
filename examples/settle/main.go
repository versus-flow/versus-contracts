package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {
	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()

	flow.TransactionFromFile("buy/settle").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
}
