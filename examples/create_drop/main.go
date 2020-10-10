package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	fmt.Println("Create artist FT wallet with 0 balance")
	//The artist owns NFTs and sells in the marketplace
	flow.CreateAccount("artist")
	flow.TransactionFromFile("setup/actor").SignProposeAndPayAs("artist").UFix64Argument("0.0").Run()

	fmt.Println("Create a drop with minimum price 10.01 that starts at tick 11 with 10 editions and the minimum bid increment of 5")
	flow.TransactionFromFile("setup/drop").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").                                                                      //marketplace location
		UFix64Argument("10.01").                                                                        //start price
		Argument(cadence.NewUInt64(11)).                                                                //start block
		StringArgument("Vincent Kamp").                                                                 //artist name
		StringArgument("when?").                                                                        //name of art
		StringArgument("https://ipfs.io/ipfs/QmURySCXsDh5tZUVVVNSnV1L8nxjVAoyChShGkvZ9NWF9A").          //image
		StringArgument("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"). //description
		Argument(cadence.NewUInt64(10)).                                                                //number of editions to use for the editioned auction
		UFix64Argument("5.0").                                                                          //min bid increment
		Run()

	flow.ScriptFromFile("check_account").AccountArgument("marketplace").StringArgument("marketplace").Run()
	flow.ScriptFromFile("get_active_auction").AccountArgument("marketplace").Run()
}
