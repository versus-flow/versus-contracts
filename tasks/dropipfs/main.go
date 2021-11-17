package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "November 18, 2021 08:00:00 AM"
	durationHrs := 4
	artistAddress := "0xb082dd2dcb0c4acf"
	artist := "Blake Jamieson"
	name := "Mr. Brown's Garden"
	editions := 10

	content := "QmdZ2ULAWYongs4Dtbo8BHst5GFrreSGRgQgVwCuKvd9yA"

	description := `Mr. Brown's Garden

Blake Jamieson

Bringing new life to a photograph captured by my dad (Patrick Jamieson) in 1969.`

	flow := gwtf.NewGoWithTheFlowMainNet()
	//	flow := gwtf.NewGoWithTheFlowDevNet()

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
		StringArgument("ipfs/image").                             //type
		UFix64Argument("0.05").                                   //artistCut 5%
		UFix64Argument("0.025").                                  //minterCut 2.5%
		RunPrintEventsFull()

}
