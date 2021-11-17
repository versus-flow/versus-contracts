package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowMainNet()

	flow.ScriptFromFile("check_account").
		AccountArgument("versus").RunReturns()

}
