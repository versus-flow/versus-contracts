package test_main

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/stretchr/testify/assert"
)

type GWTFTestUtils struct {
	T    *testing.T
	GWTF *gwtf.GoWithTheFlow
}

func NewGWTFTest(t *testing.T) *GWTFTestUtils {
	return &GWTFTestUtils{T: t, GWTF: gwtf.NewTestingEmulator()}
}

func (gt *GWTFTestUtils) setup() *GWTFTestUtils {
	//first step create the adminClient as the fin user

	flow := gt.GWTF
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("account").UFix64Argument("100.0").Test(gt.T).AssertSuccess() //TODO test events
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("marketplace").UFix64Argument("100.0").Test(gt.T).AssertSuccess()

	//create the AdminPublicAndSomeOtherCollections
	flow.TransactionFromFile("versus1").
		SignProposeAndPayAs("marketplace").Test(gt.T).AssertSuccess()

	//link in the server in the versus client
	flow.TransactionFromFile("versus2").
		SignProposeAndPayAsService().
		AccountArgument("marketplace").Test(gt.T).AssertSuccess()

	return gt.tickClock("1.0")
}

func (gt *GWTFTestUtils) setupDutchAuction() uint64 {

	flow := gt.GWTF
	err := flow.UploadImageAsDataUrl("bull.png", "marketplace")
	assert.NoError(gt.T, err)
	//	now sure on how to test this really

	time := gt.currentTime()
	startTimeString := fmt.Sprintf("%f00", time)
	//todo: should we add some parameters here?
	events, err := flow.TransactionFromFile("dutchAuction").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").       //marketplace location
		UFix64Argument("10.00").         //start price
		UFix64Argument(startTimeString). //start time
		StringArgument("Kinger9999").    //artist name
		StringArgument("BULL").          //name of art
		StringArgument("Teh bull").      //description
		UInt64Argument(10).              //number of art
		UFix64Argument("1.0").           //floor price
		UFix64Argument("0.9").           //decreasePriceFactor
		UFix64Argument("0.0").           //decreasePriceAmount
		UFix64Argument("2.0").           //duration
		UFix64Argument("0.05").          //artistCut 5%
		UFix64Argument("0.025").         //minterCut 2.5%
		RunE()

	assert.NoError(gt.T, err)
	assert.Equal(gt.T, 31, len(events))

	dutchAcutionEvent := events[30]
	return dutchAcutionEvent.Value.Fields[4].ToGoValue().(uint64)

}

func (gt *GWTFTestUtils) tickClock(time string) *GWTFTestUtils {
	gt.GWTF.TransactionFromFile("clock").SignProposeAndPayAs("marketplace").UFix64Argument(time).Test(gt.T).AssertSuccess()
	return gt
}

func (gt *GWTFTestUtils) createArtCollectionAndMintFlow(name string, amount string) *GWTFTestUtils {

	flow := gt.GWTF
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument(name).UFix64Argument(amount).Test(gt.T).AssertSuccess()
	flow.TransactionFromFile("art_collection").SignProposeAndPayAs(name).Test(gt.T).AssertSuccess()
	return gt
}

func (gt *GWTFTestUtils) currentTime() float64 {
	value, err := gt.GWTF.Script(`import Clock from "../contracts/Clock.cdc"
pub fun main() :  UFix64 {
    return Clock.time()
}`).RunReturns()
	assert.NoErrorf(gt.T, err, "Could not execute script")
	currentTime := value.String()
	res, err := strconv.ParseFloat(currentTime, 64)
	assert.NoErrorf(gt.T, err, "Could not parse as float")
	return res
}

func (gt *GWTFTestUtils) dutchTickFullfilled(id uint64, amount string) *GWTFTestUtils {

	flow := gt.GWTF
	flow.TransactionFromFile("dutchAuctionTick").
		SignProposeAndPayAs("marketplace").
		UInt64Argument(id).
		Test(gt.T).AssertSuccess().
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionSettle", map[string]interface{}{
			"price":   amount,
			"auction": fmt.Sprintf("%d", id),
		}))
	return gt
}

func (gt *GWTFTestUtils) dutchTickNotFullfilled(id uint64, acceptedBids int, amount string, startedAt string) *GWTFTestUtils {

	flow := gt.GWTF
	flow.TransactionFromFile("dutchAuctionTick").
		SignProposeAndPayAs("marketplace").
		UInt64Argument(id).
		Test(gt.T).AssertSuccess().
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionTick", map[string]interface{}{
			"acceptedBids": fmt.Sprintf("%d", acceptedBids),
			"tickPrice":    amount,
			"auction":      fmt.Sprintf("%d", id),
			"tickTime":     fmt.Sprintf("%s0000000", startedAt),
			"totalItems":   "10",
		}))
	return gt
}

func (gt *GWTFTestUtils) dutchBid(account string, auctionId uint64, amount string, bidNumber uint64, order uint64, tick string, bidType string, bidSize uint64) *GWTFTestUtils {

	bidderAddress := fmt.Sprintf("0x%s", gt.GWTF.Account(account).Address().String())
	debugMessage := fmt.Sprintf("Bid %s index=%d amount=%s0000000 tick=%s bidder=%s bidid=%d bidSize=%d", bidType, order, amount, tick, bidderAddress, bidNumber, bidSize)
	flow := gt.GWTF
	flow.TransactionFromFile("dutchBid").
		SignProposeAndPayAs(account).
		AccountArgument("account").
		UInt64Argument(auctionId). //id of auction
		UFix64Argument(amount).    //amount to bid
		Test(gt.T).AssertSuccess().
		AssertDebugLog(debugMessage)
		/*		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionBid", map[string]interface{}{
					"amount":  fmt.Sprintf("%s0000000", amount),
					"bid":     fmt.Sprintf("%d", bidNumber),
					"bidder":  bidderAddress,
					"auction": fmt.Sprintf("%d", auctionId),
					"order":   fmt.Sprintf("%d", order),
					"tick":    tick,
				}))
		*/

	return gt
}
