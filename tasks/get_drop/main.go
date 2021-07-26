package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	dropID, ok := os.LookupEnv("drop")
	if !ok {
		fmt.Println("drop is not present")
		os.Exit(1)
	}

	drop, err := strconv.ParseUint(dropID, 10, 64)
	if err != nil {
		fmt.Println("could not parse drop as number")
	}
	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.ScriptFromFile("drop_status").UInt64Argument(drop).Run()

	//flow.ScriptFromFile("drop_art").UInt64Argument(drop).Run()

}
