package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "January 27, 2022 08:00:00 AM"
	durationHrs := 4
	artistAddress := "0x012f215167af8d8d"
	artist := "Buba Viedma"
	name := "Smile, is the Apocalypse"
	editions := 10

	content := "QmZgYyUvYHm4Y4G3wA1agPKwwygxyvx6QKx6JKdJzutz1b"

	description := `Soon we will all die, but we will die with a smile on our faces.`

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
		StringArgument("ipfs/video").                             //type
		UFix64Argument("0.05").                                   //artistCut 5%
		UFix64Argument("0.025").                                  //minterCut 2.5%
		RunPrintEventsFull()

}
