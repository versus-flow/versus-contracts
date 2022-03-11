package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	startTime := "February 18, 2022 08:00:00 PM"
	durationHrs := 43
	artistAddress := "0x49b9273b4fdbcc0e"
	artist := "TheFirstMint"
	name := "LG'S HOLO ICON PACK AUCTION"
	editions := 0
	description := `The first ever non-official NBA Top Shot pack auction is here! LG Doucet from The First Mint is going to be auctioning his Series 2 HOLO ICON Drop 1 pack as part of BASKETBALL & BLOCKCHAIN WEEK. You'll have all weekend to bid on the pack, which will then be opened LIVE on Twitter Spaces with the lucky winner. All funds raised will be donated to the Canadian Mental Health Association.`

	imageUrl := "https://uploads.linear.app/b5013517-8161-4940-b2a0-d5fc21b1fafb/130f4650-8337-4ef0-b6cc-127587c34f3c/357104a9-8d08-4423-becd-6334b128763b"

	flow := overflow.NewOverflowMainnet().Start()
	//flow := gwtf.NewGoWithTheFlowDevNet()

	//	err := flow.UploadImageAsDataUrl(imageUrl, "admin")
	err := flow.DownloadImageAndUploadAsDataUrl(imageUrl, "admin")
	if err != nil {
		panic(err)
	}

	flow.TransactionFromFile("drop").
		SignProposeAndPayAs("admin").
		Args(flow.Arguments().
			RawAccount(artistAddress).
			UFix64(1.00).                                             //start price
			DateStringAsUnixTimestamp(startTime, "America/New_York"). //time
			String(artist).                                           //artist name
			String(name).                                             //name
			String(description).                                      //description
			UInt64(uint64(editions)).                                 //number of editions
			UFix64(2.0).                                              //min bid increment
			UFix64(4.0).                                              //min bid increment unique
			UFix64(float64(durationHrs * 60 * 60)).                   //duration 60 * 60 * 24 1 day
			UFix64(300.0).                                            //extensionOnLateBid 5 * 60 5 min
			String("image/dataurl").                                  //type
			UFix64(0.05).                                             //artistCut 5%
			UFix64(0.025)).                                           //minterCut 2.5%
		RunPrintEventsFull()

}
