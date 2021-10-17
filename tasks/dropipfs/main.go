package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "October 15, 2021 01:00:00 AM"
	durationHrs := 4
	artistAddress := "0x530212d1a4c6f7eb"
	artist := "Sample"
	name := "Sample6"
	editions := 0
	content := "QmZ8dHcccdqNBNgEHKnSMCVjAAhLc293tmhDZZcptfF5eD"
	description := `This is a sample video drop with large video`

	//flow := gwtf.NewGoWithTheFlowMainNet()
	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.TransactionFromFile("drop_single").
		SignProposeAndPayAs("admin").
		RawAccountArgument(artistAddress).
		AccountArgument("versus").
		UFix64Argument("1.00").                                   //start price
		DateStringAsUnixTimestamp(startTime, "America/New_York"). //time
		StringArgument(artist).                                   //artist name
		StringArgument(name).                                     //name
		StringArgument(description).                              //description
		StringArgument(content).                                  //content
		UInt64Argument(uint64(editions)).                         //number of editions
		UFix64Argument("2.0").                                    //min bid increment
		UFix64Argument("4.0").                                    //min bid increment unique
		UFix64Argument(fmt.Sprintf("%d.0", durationHrs*60*60)).   //duration 60 * 60 * 24 1 day
		UFix64Argument("300.0").                                  //extensionOnLateBid 5 * 60 5 min
		StringArgument("ipfs/video").                             //type
		UFix64Argument("0.05").                                   //artistCut 5%
		UFix64Argument("0.025").                                  //minterCut 2.5%
		RunPrintEventsFull()

}
