package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	flow := overflow.NewOverflowMainnet().Start()

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
		Args(flow.Arguments().RawAccount(account).UInt64(artId)).
		RunPrintEventsFull()

}
