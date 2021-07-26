package main

import (
	"fmt"
	"strconv"
	"time"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

//NB! start from root dir with makefile
func main() {

	now := time.Now()
	t := now.Unix() - 5
	timeString := strconv.FormatInt(t, 10) + ".0"

	flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("account").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("artist").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("marketplace").UFix64Argument("100.0").RunPrintEventsFull()

	//create the AdminPublicAndSomeOtherCollections
	flow.TransactionFromFile("versus1").
		SignProposeAndPayAs("marketplace").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("versus2").
		SignProposeAndPayAsService().
		AccountArgument("marketplace").
		RunPrintEventsFull()

	fmt.Println("Upload image")
	flow.UploadImageAsDataUrl("ekaitza.png", "marketplace")

	fmt.Println("Create a drop in versus that is already started with 10 editions")
	flow.TransactionFromFile("drop").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").                                                                      //marketplace location
		UFix64Argument("10.00").                                                                        //start price
		UFix64Argument(timeString).                                                                     //start time
		StringArgument("Vincent Kamp").                                                                 //artist name
		StringArgument("when?").                                                                        //name of art
		StringArgument("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"). //description
		Argument(cadence.NewUInt64(10)).                                                                //number of editions to use for the editioned auction
		UFix64Argument("5.0").                                                                          //min bid increment
		UFix64Argument("10.0").                                                                         //min bid increment unique
		UFix64Argument("5.0").                                                                          //duration
		RunPrintEventsFull()

	fmt.Println("Setup a buyer and make him bid on the unique auction")
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer1").UFix64Argument("1000.0").RunPrintEventsFull()

	flow.TransactionFromFile("bid").
		SignProposeAndPayAs("buyer1").
		AccountArgument("account").
		UInt64Argument(1).            //id of drop
		Argument(cadence.UInt64(11)). //id of unique auction auction to bid on
		UFix64Argument("10.00").      //amount to bid
		RunPrintEventsFull()

	flow.TransactionFromFile("bid").
		AccountArgument("account").
		RawAccountArgument("0xf8d6e0586b0a20c7"). //we use raw argument here because of a limitation on how go-with-the-flow is built
		UInt64Argument(1).                        //id of drop
		Argument(cadence.UInt64(11)).             //id of unique auction auction to bid on
		UFix64Argument("30.00").                  //amount to bid
		RunPrintEventsFull()

	fmt.Println("Go to website to bid there")
	fmt.Println("Tick the clock to make the auction end and settle it")
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	fmt.Println("settle")

	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	flow.TransactionFromFile("settle").SignProposeAndPayAs("marketplace").UInt64Argument(1).RunPrintEventsFull()

	flow.ScriptFromFile("check_account").AccountArgument("buyer1").Run()
	flow.ScriptFromFile("check_account").AccountArgument("buyer2").Run()
	flow.ScriptFromFile("check_account").AccountArgument("artist").Run()
	flow.ScriptFromFile("check_account").AccountArgument("marketplace").Run()

	flow.ScriptFromFile("drop_status").UInt64Argument(1).Run()
	flow.TransactionFromFile("destroy_versus").SignProposeAndPayAsService().UInt64Argument(1).RunPrintEventsFull()
}
