package main

import (
	"github.com/0xAlchemist/go-flow-tooling/tooling"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const rocks = "rocks"
const auction = "auction"

func main() {
	flow := tooling.NewFlowConfigLocalhost()

	flow.DeployContract(nonFungibleToken)
	flow.DeployContract(demoToken)
	flow.DeployContract(rocks)
	flow.DeployContract(auction)

	flow.SendTransaction("setup/setup_account_1", demoToken)
	flow.SendTransaction("setup/setup_account_2", rocks)
	flow.SendTransaction("setup/setup_account_3_and_4", auction)
	flow.SendTransaction("setup/setup_account_3_and_4", nonFungibleToken)
	flow.SendTransaction("setup/setup_account_1_tx_minting", demoToken)

	flow.RunScript("check_setup")
}
