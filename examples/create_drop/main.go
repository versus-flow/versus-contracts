package main

import (
	"fmt"

	"github.com/onflow/cadence"
	"github.com/versus-flow/go-flow-tooling/tooling"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const art = "Art"
const versus = "Versus"
const auction = "Auction"

const marketplace = "Marketplace"
const artist = "Artist"
const buyer1 = "Buyer1"
const buyer2 = "Buyer2"

func ufix(input string) cadence.UFix64 {
	amount, err := cadence.NewUFix64(input)
	if err != nil {
		panic(err)
	}
	return amount
}

func main() {
	flow := tooling.NewFlowConfigLocalhost()

	fmt.Println("Create artist FT wallet with 0 balance")
	//The artist owns NFTs and sells in the marketplace
	flow.CreateAccount(artist)
	flow.SendTransactionWithArguments("setup/actor", artist, ufix("0.0"))

	fmt.Println("Creat a drop with minimum price 10.01 that starts at tick 11 with 10 editions and the minimum bid increment of 5")
	flow.SendTransactionWithArguments("setup/drop", marketplace,
		flow.FindAddress(artist),          //marketplace locaion
		ufix("10.01"),                     //start price
		cadence.NewUInt64(11),             //start block
		cadence.NewString("Vincent Kamp"), //artist name
		cadence.NewString("when?"),        //name of art
		cadence.NewString("https://instagram.fosl3-1.fna.fbcdn.net/v/t51.2885-15/e35/104280574_270973930649849_1688474937245466725_n.jpg?_nc_ht=instagram.fosl3-1.fna.fbcdn.net&_nc_cat=105&_nc_ohc=RbxHzbEtUKAAX_snGNw&oh=285144010b5a99883a1f28e73311b179&oe=5F6B948F"),
		cadence.NewString("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"),
		cadence.NewUInt64(10), //number of editions to use for the editioned auction
		ufix("5.0"))           //minimum bid increment
	flow.RunScript("check_account", flow.FindAddress(marketplace), cadence.NewString("marketplace"))
	flow.RunScript("get_active_auction", flow.FindAddress(marketplace))
}
