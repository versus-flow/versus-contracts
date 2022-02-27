package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	startTime := "February 10, 2022 08:00:00 AM"
	durationHrs := 28
	artistAddress := "0x3db67c59f4da358d"
	artist := "Elise Swopes"
	name := "Rise and Shine"
	editions := 10
	description := `Black Women on Boards aims to remove the obstacles Black women executives face when pursuing board memberships. On February 8, BWOB rings the opening bell at NASDAQ.

Despite her obstacles, Elise Swopes, the Black female fine artist of Rise and Shine, made a name for herself using only her iPhone as a tool for building her vision. This artwork is created in celebration of Patricia Roberts Harris, the first Black woman to serve on a Fortune 500 board, and the “Lift As You Climb” Fellowship, created to inspire the next generation of diverse talent.`

	imageUrl := "https://uploads.linear.app/b5013517-8161-4940-b2a0-d5fc21b1fafb/14fb3f01-9f9e-4252-b1c3-5c06c30939d3/8698ee37-1182-49cc-96ef-4b0ec7fc8f05"

	flow := gwtf.NewGoWithTheFlowMainNet()
	//	flow := gwtf.NewGoWithTheFlowDevNet()
	err := flow.DownloadImageAndUploadAsDataUrl(imageUrl, "admin")
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
