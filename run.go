package main

import (
	"github.com/0xAlchemist/go-flow-tooling/tooling"
	"github.com/davecgh/go-spew/spew"
)

func main() {
	flow := tooling.NewFlowConfigLocalhost()

	spew.Dump(flow)

	// flow.DeployContract("NonFungibleToken")
}
