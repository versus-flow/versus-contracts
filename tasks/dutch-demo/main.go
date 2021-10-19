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
	t := now.Unix()
	timeString := strconv.FormatInt(t, 10) + ".0"

	//flow := gwtf.NewGoWithTheFlowInMemoryEmulator()
	flow := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("account").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("marketplace").UFix64Argument("100.0").RunPrintEventsFull()

	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("artist").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("art_collection").SignProposeAndPayAs("artist").RunPrintEventsFull()

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
	flow.UploadImageAsDataUrl("bull.png", "marketplace")

	fmt.Println("Create a dutch auction")
	flow.TransactionFromFile("dutchAuction").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").    //marketplace location
		UFix64Argument("11.00").      //start price
		UFix64Argument(timeString).   //start time
		StringArgument("Kinger9999"). //artist name
		StringArgument("BULL").       //name of art
		StringArgument("Teh bull").
		Argument(cadence.NewUInt64(10)). //number of editions to use for the editioned auction
		UFix64Argument("1.0").           //floor price
		UFix64Argument("0.95").          //decreasePriceFactor
		UFix64Argument("1.0").           //decreasePriceAmount
		UFix64Argument("2.0").           //duration
		UFix64Argument("0.05").          //artistCut 5%
		UFix64Argument("0.025").         //minterCut 2.5%
		StringArgument("image/dataurl").
		RunPrintEventsFull()

	fmt.Println("Setup a buyer and make him bid on the unique auction")
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer1").UFix64Argument("1000.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer2").UFix64Argument("1000.0").RunPrintEventsFull()

	flow.TransactionFromFile("dutchBid").
		SignProposeAndPayAs("buyer1").
		AccountArgument("account").
		UInt64Argument(62).      //id of auction
		UFix64Argument("10.00"). //amount to bid
		RunPrintEventsFull()

	flow.ScriptFromFile("dutchAuctionUserBid").AccountArgument("buyer1").Run()

	flow.TransactionFromFile("dutchBidCancel").
		SignProposeAndPayAs("buyer1").
		UInt64Argument(70). //id of bid
		RunPrintEventsFull()

	/*
		flow.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("buyer1").
			AccountArgument("account").
			UInt64Argument(60).     //id of auction
			UFix64Argument("9.00"). //amount to bid
			RunPrintEventsFull()

		flow.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("buyer1").
			AccountArgument("account").
			UInt64Argument(60).     //id of auction
			UFix64Argument("8.01"). //amount to bid
			RunPrintEventsFull()

	*/
}
