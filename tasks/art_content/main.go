package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowMainNet()

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}
	artId, ok := os.LookupEnv("id")
	if !ok {
		fmt.Println("drop is not present")
		os.Exit(1)
	}

	id, err := strconv.ParseUint(artId, 10, 64)
	if err != nil {
		fmt.Println("could not parse drop as number")
	}

	flow.ScriptFromFile("content_art").
		RawAccountArgument(account).
		UInt64Argument(id).Run()

}
