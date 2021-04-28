package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlow(".flow-prod.json")

	flow.TransactionFromFile("buy/settle_first").SignProposeAndPayAs("admin").RunPrintEventsFull()

}
