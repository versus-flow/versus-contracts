package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "November 30, 2021 08:00:00 AM"
	durationHrs := 72
	artistAddress := "0xdc5b887c1bfb1b10"
	artist := "Bjartek"
	name := "LeetLines"
	editions := 5
	description := `My leety lines`

	imageUrl := "contourline-1637789359.jpeg"

	//flow := gwtf.NewGoWithTheFlowMainNet()
	flow := gwtf.NewGoWithTheFlowDevNet()

	err := flow.UploadImageAsDataUrl(imageUrl, "admin")
	//	err := flow.DownloadImageAndUploadAsDataUrl(imageUrl, "admin")
	if err != nil {
		panic(err)
	}

	flow.TransactionFromFile("drop").
		SignProposeAndPayAs("admin").
		//AccountArgument("artist").
		RawAccountArgument(artistAddress).
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
