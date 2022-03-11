package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	startTime := "March 3, 2022 08:00:00 AM"
	durationHrs := 4
	artistAddress := "0xb383962a1dab350b"
	artist := "Anxo Vizcaíno"
	name := "Tales of Errantia: Epilogue III"
	editions := 10

	content := "QmccTojfeB41vE33N6ykHquaZEu5SdkZc8zpfrypgpxZSu"

	description := `’Tales of Errantia: Epilogue’ recaps the original ‘Tales of Errantia’ series (2017) in a brand new format that brings animation and audio to the original scenes, along with new additions and refined details. Exploring topics such as our need for irrepressible search, obstacles to overcome and living together with nature, this third piece brings an overview of this whimsical place.

Seamless loop, H264 MP4, 2000 x 1500 pixels.`
	o := overflow.NewOverflowMainnet().Start()

	o.TransactionFromFile("drop_ipfs").
		SignProposeAndPayAs("admin").
		Args(o.Arguments().
			RawAccount(artistAddress).
			UFix64(1.00).                                             //start price
			DateStringAsUnixTimestamp(startTime, "America/New_York"). //time
			String(artist).                                           //artist name
			String(name).                                             //name
			String(description).                                      //description
			String(content).                                          //content
			UInt64(uint64(editions)).                                 //number of editions
			UFix64(2.0).                                              //min bid increment
			UFix64(4.0).                                              //min bid increment unique
			UFix64(float64(durationHrs * 60 * 60)).                   //duration 60 * 60 * 24 1 day
			UFix64(300.0).                                            //extensionOnLateBid 5 * 60 5 min
			String("ipfs/video").                                     //type
			UFix64(0.05).                                             //artistCut 5%
			UFix64(0.025)).                                           //minterCut 2.5%
		RunPrintEventsFull()

}
