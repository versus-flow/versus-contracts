package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "October 29, 2021 5:00:00 PM"
	durationHrs := 48
	artist := "Kinger9999"
	name := "Bull"
	editions := 10
	description := `Teh Bull`

	flow := gwtf.NewGoWithTheFlowDevNet()

	err := flow.UploadImageAsDataUrl("bull.png", "admin")
	if err != nil {
		panic(err)
	}

	flow.TransactionFromFile("drop").
		SignProposeAndPayAs("admin").
		AccountArgument("artist").
		UFix64Argument("1.00").                                   //start price
		DateStringAsUnixTimestamp(startTime, "America/New_York"). //time
		StringArgument(artist).                                   //artist name
		StringArgument(name).                                     //name
		StringArgument(description).                              //description
		UInt64Argument(uint64(editions)).                         //number of editions
		UFix64Argument("2.0").                                    //min bid increment
		UFix64Argument("4.0").                                    //min bid increment unique
		UFix64Argument(fmt.Sprintf("%d.0", durationHrs*60*60)).   //duration 60 * 60 * 24 1 day
		UFix64Argument("300.0").                                  //extensionOnLateBid 5 * 60 5 min
		StringArgument("image/dataurl").                          //type
		UFix64Argument("0.05").                                   //artistCut 5%
		UFix64Argument("0.025").                                  //minterCut 2.5%

		RunPrintEventsFull()

}
