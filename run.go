package main

import "github.com/0xAlchemist/go-flow-tooling/tooling"

func main() {
	flow := tooling.NewFlowConfigLocalhost()

	flow.DeployContract("NonFungibleToken")
}
