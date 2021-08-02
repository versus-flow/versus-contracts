package main

import (
	"strconv"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowMainNet()

	value := flow.ScriptFromFile("check_unsettled_drop").AccountArgument("versus").RunReturns()

	stringValue := value.String()

	if stringValue != "nil" {

		number, err := strconv.ParseUint(stringValue, 10, 64)
		if err != nil {
			panic(err)
		}
		flow.TransactionFromFile("settle").SignProposeAndPayAs("admin").UInt64Argument(number).RunPrintEventsFull()
	}

}
