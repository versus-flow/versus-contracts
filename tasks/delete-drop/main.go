package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/overflow/overflow"
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
	flow := overflow.NewOverflowMainnet().Start()

	flow.ScriptFromFile("drop_status").Args(flow.Arguments().UInt64(drop)).Run()

	//	value := flow.ScriptFromFile("not_valid_drop").UInt64Argument(drop).RunReturns()

	//	if value == cadence.Bool(true) {
	fmt.Println("can we delete this drop?, press CTRL-C to abort, or any other key to delete")
	fmt.Scanln()
	flow.TransactionFromFile("destroy_versus").SignProposeAndPayAs("admin").Args(flow.Arguments().UInt64(drop)).Run()
	//	} else {
	//		fmt.Println("We cannot delete this")
	//	}

}
