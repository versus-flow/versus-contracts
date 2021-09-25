package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	startTime := "September 24, 2021 08:00:00 AM"
	durationHrs := 488
	artistAddress := "0x530212d1a4c6f7eb"
	artist := "Sample"
	name := "Sample4"
	editions := 0
	content := "Qmc2LbzPHvaGzvPLuxjkp7jjVnBcxyDDXGXRdb9uhhTDme"
	description := `This is a sample audio drop`

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
		StringArgument("flow").
		UFix64Argument("0.05").  //artistCut 5%
		UFix64Argument("0.025"). //minterCut 2.5%
		Argument(cadence.Path{Domain: "public", Identifier: "flowTokenReceiver"}).
		RunPrintEventsFull()

}
