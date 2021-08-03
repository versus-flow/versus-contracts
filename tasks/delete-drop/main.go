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
	flow := gwtf.NewGoWithTheFlowMainNet()

	flow.ScriptFromFile("drop_status").UInt64Argument(drop).Run()

	//	value := flow.ScriptFromFile("not_valid_drop").UInt64Argument(drop).RunReturns()

	//	if value == cadence.Bool(true) {
	fmt.Println("can we delete this drop?, press CTRL-C to abort, or any other key to delete")
	fmt.Scanln()
	flow.TransactionFromFile("destroy_versus").SignProposeAndPayAs("admin").UInt64Argument(drop).Run()
	//	} else {
	//		fmt.Println("We cannot delete this")
	//	}

}
