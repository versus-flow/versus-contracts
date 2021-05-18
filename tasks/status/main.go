package main

import (

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.ScriptFromFile("check_account_testnet").
		AccountArgument("admin").RunReturns()

}
