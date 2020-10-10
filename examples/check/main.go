package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {
	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.ScriptFromFile("check_account").AccountArgument("buyer1").StringArgument("buyer1").Run()
	flow.ScriptFromFile("check_account").AccountArgument("buyer2").StringArgument("buyer2").Run()
	flow.ScriptFromFile("check_account").AccountArgument("artist").StringArgument("artist").Run()
	flow.ScriptFromFile("check_account").AccountArgument("marketplace").StringArgument("marketplace").Run()

}
