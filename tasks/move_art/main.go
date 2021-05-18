package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}
	art, ok := os.LookupEnv("art")
	if !ok {
		fmt.Println("art is not present")
		os.Exit(1)
	}
	artId, err := strconv.ParseUint(art, 10, 64)
	if err != nil {
		fmt.Println("could not parse drop as number")
	}


	flow.TransactionFromFile("move_art").
		SignProposeAndPayAs("admin").
		RawAccountArgument(account).
		UInt64Argument(artId).
		RunPrintEventsFull()

}
