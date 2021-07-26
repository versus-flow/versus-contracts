package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "July 29, 2021 08:00:00 AM"
	durationHrs := 4
	artistAddress := "0x1b945b52f416ddf9"
	artist := "Jos"
	name := "Solitude 2.0"
	editions := 15
	description := `In the near future,
When we have conquered all
We will still be strangers to ourselves
We will bridge the open space
We will witness new wonders
But in the immense distance of the cosmos
We will be smaller and smaller.`

	imageUrl := "https://uploads.linear.app/b5013517-8161-4940-b2a0-d5fc21b1fafb/67a95870-468d-478b-9ee8-e21bbf87e35f/9af1ea1a-89d1-40fa-9390-43fd5d52e284"

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
		RunPrintEventsFull()

}
