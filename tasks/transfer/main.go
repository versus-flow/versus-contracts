package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowMainNet()

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}

	amount, ok := os.LookupEnv("amount")
	if !ok {
		fmt.Println("amount is not present")
		os.Exit(1)
	}

	flow.TransactionFromFile("transfer_flow_versus").
		SignProposeAndPayAs("admin").
		UFix64Argument(amount).
		RawAccountArgument(account).
		RunPrintEventsFull()
}
