package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	startTime := "October 19, 2021 14:00:00 PM"
	artist := "Kinger9999"
	name := "Teh Bull"
	editions := 10
	description := `The bull`
	startPrice := "100000.0"
	floorPrice := "10.0"
	tickDuration := "300.0"
	priceDecreasePerTick := "0.95"

	//flow := gwtf.NewGoWithTheFlowMainNet()
	flow := gwtf.NewGoWithTheFlowDevNet()

	err := flow.UploadImageAsDataUrl("bull.png", "admin")
	if err != nil {
		panic(err)
	}
	flow.TransactionFromFile("dutchAuction").
		SignProposeAndPayAs("admin").
		AccountArgument("artist").
		//RawAccountArgument(artistAddress).
		UFix64Argument(startPrice).                               //start price
		DateStringAsUnixTimestamp(startTime, "America/New_York"). //time
		StringArgument(artist).                                   //artist name
		StringArgument(name).                                     //name
		StringArgument(description).                              //description
		UInt64Argument(uint64(editions)).                         //number of editions
		UFix64Argument(floorPrice).                               //floor price
		UFix64Argument(priceDecreasePerTick).                     //decreasePriceFactor
		UFix64Argument("0.0").                                    //decreasePriceAmount
		UFix64Argument(tickDuration).                             //tickDuration
		UFix64Argument("0.05").                                   //artistCut 5%
		UFix64Argument("0.025").                                  //minterCut 2.5%
		StringArgument("image/dataurl").
		RunPrintEventsFull()

}
