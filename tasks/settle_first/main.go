package main

import (
	"strconv"

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlow(".flow-prod.json")

	value := flow.ScriptFromFile("check_unsettled_drop").RunReturns()

	stringValue := value.String()

	if stringValue != "nil" {

		number, err := strconv.ParseUint(stringValue, 10, 64)
		if err != nil {
			panic(err)
		}
		flow.TransactionFromFile("buy/settle_testnet").SignProposeAndPayAs("admin").UInt64Argument(number).RunPrintEventsFull()
	}

}
