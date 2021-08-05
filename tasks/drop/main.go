package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "August 5, 2021 08:00:00 AM"
	durationHrs := 4
	artistAddress := "0xb1510e68de5655e5"
	artist := "LOREM"
	name := "PATH"
	editions := 15
	description := `The process of creating art feels like a path that helps me to escape from negativity. It helps me to disconnect, decompress, and finally to define the emotions I want to express. I'd love to bring you with me on this path.`

	imageUrl := "https://dl.dropboxusercontent.com/s/bi3n8c5jwn4ki0c/PATH_LOREM.jpg"

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
		StringArgument("flow").
		UFix64Argument("0.05").  //artistCut 5%
		UFix64Argument("0.025"). //minterCut 2.5%
		RunPrintEventsFull()

}
