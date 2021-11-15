package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "November 3, 2021 12:00:00 PM"
	durationHrs := 24
	artistAddress := "0x5643c6c249c52fb8"
	artist := "Leo Isikdogan"
	name := "Geodiversity of an Exoplanet"
	editions := 20
	content := "QmU5W5t4H4cEJhXWfZTxHyUn9aSoq3VMtv6hTkYV1Tdx7u"
	description := `This work explores geodiversity in the context of extraterrestrial environments. It is an artistic representation of Earth-like planetary landscapes we may one day encounter on celestial bodies. The work was created using a custom-designed AI art model and creative algorithms. 

Verisart Certified: https://verisart.com/edition/a8afeb80-bf29-43a7-84f8-ac1d89472a7e`

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
