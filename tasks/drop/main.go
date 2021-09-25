package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "September 2, 2021 08:00:00 AM"
	durationHrs := 4
	artistAddress := "0xfb1b4662ca2f6dbd"
	artist := "Zigor"
	name := "CoKing"
	editions := 10
	description := `You may have heard of it, it is known to humans as COVID-19, SARS-CoV-2 or CORONA. There has been much speculation about his origins, about his creation, but what no human being knows is that his real name is CoKing, a creation of the clumsy and evil Mago Rata Pollo, in his effort to create a magical army of minions.

CoKing has turned out to be the only efficient soldier created by Rata Pollo, a great success. In the year 2057 there are almost no humans left. Only a tiny expression of what they once were: the resistance. CoKing has lost count of the waves he has surfed but he reinvents himself in each one to continue his mission. He doesn't have much left, or so he thinks...`

	imageUrl := "https://uploads.linear.app/b5013517-8161-4940-b2a0-d5fc21b1fafb/68cf741b-4a68-4483-af31-0195b6443eb3/41dc133d-2136-4bea-b251-116fce4850d1"

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
