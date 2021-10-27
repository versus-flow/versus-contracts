package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestDutchAuction(t *testing.T) {

	t.Run("Should start and fullfill an auction", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "100.0").
			createArtCollectionAndMintFlow("buyer2", "100.0")

		auctionId := gwtfTest.setupDutchAuction()

		gwtfTest.dutchBid("buyer1", auctionId, "10.0", 72).tickClock("2.0")
		gwtfTest.dutchTickNotFullfilled(auctionId, 1, "9.00000000", "3.0")
		expectedStatus := `A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionStatus(status: "Ongoing", startTime: 1.00000000, currentTime: 3.00000000, currentPrice: 9.00000000, totalItems: 10, acceptedBids: 1, tickStatus: {1.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 10.00000000, startedAt: 1.00000000, acceptedBids: 1, cumulativeAcceptedBids: 1)}, metadata: {"nftType": "A.f8d6e0586b0a20c7.Art.NFT", "name": "BULL", "artist": "Kinger9999", "artistAddress": "0x1cf0e2f2f715450", "description": "Teh bull", "type": "image/dataurl", "contentId": "0", "url": ""})`

		assert.Equal(gwtfTest.T, expectedStatus, gwtfTest.auctionStatus(auctionId))

		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 76)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 78)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 80)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 82)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 84)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 86)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 88)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 90)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 92)

		gwtfTest.tickClock("3.0")
		gwtfTest.dutchTickFullfilled(auctionId, "9.00000000")

		expectedStatus = `A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionStatus(status: "Finished", startTime: 1.00000000, currentTime: 6.00000000, currentPrice: 9.00000000, totalItems: 10, acceptedBids: 10, tickStatus: {1.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 10.00000000, startedAt: 1.00000000, acceptedBids: 1, cumulativeAcceptedBids: 1), 3.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 9.00000000, startedAt: 3.00000000, acceptedBids: 9, cumulativeAcceptedBids: 10)}, metadata: {"nftType": "A.f8d6e0586b0a20c7.Art.NFT", "name": "BULL", "artist": "Kinger9999", "artistAddress": "0x1cf0e2f2f715450", "description": "Teh bull", "type": "image/dataurl", "contentId": "0", "url": ""})`
		assert.Equal(gwtfTest.T, expectedStatus, gwtfTest.auctionStatus(auctionId))

	})

	t.Run("Should insert bids that are greater before a smaller bid", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "100.0").
			createArtCollectionAndMintFlow("buyer2", "100.0")

		auctionId := gwtfTest.setupDutchAuction()

		gwtfTest.dutchBid("buyer1", auctionId, "9.8", 72)
		gwtfTest.dutchBid("buyer2", auctionId, "9.9", 76)
	})

	t.Run("Should return cash if you bid more then roof", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("buyer1", "100.0")

		bidderAddress := fmt.Sprintf("0x%s", gwtfTest.GWTF.Account("buyer1").Address().String())
		auctionId := gwtfTest.setupDutchAuction()
		amount := "11.0"
		bidNumber := 67
		gwtfTest.GWTF.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("buyer1").
			AccountArgument("account").
			UInt64Argument(auctionId). //id of auction
			UFix64Argument(amount).    //amount to bid
			Test(gwtfTest.T).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionBid", map[string]interface{}{
				"amount":  "10.00000000",
				"bid":     fmt.Sprintf("%d", bidNumber),
				"bidder":  bidderAddress,
				"auction": fmt.Sprintf("%d", auctionId),
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": "1.00000000",
				"to":     bidderAddress,
			}))

	})

	t.Run("Should be able to increase bid", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "100.0").
			createArtCollectionAndMintFlow("buyer2", "100.0")

		auctionId := gwtfTest.setupDutchAuction()

		gwtfTest.dutchBid("buyer1", auctionId, "9.1", 72)
		gwtfTest.dutchBid("buyer2", auctionId, "9.5", 76)

		bidderAddress := fmt.Sprintf("0x%s", gwtfTest.GWTF.Account("buyer1").Address().String())

		bidId := 72
		value := gwtfTest.getBidIds("buyer1")
		assert.Equal(gwtfTest.T, fmt.Sprintf("[%d]", bidId), value)
		amount := "0.5"
		gwtfTest.GWTF.TransactionFromFile("dutchBidIncrease").
			SignProposeAndPayAs("buyer1").
			UInt64Argument(uint64(bidId)). //id of bid
			UFix64Argument(amount).        //amount to bid
			Test(gwtfTest.T).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionBidIncreased", map[string]interface{}{
				"amount":  "9.60000000",
				"bid":     fmt.Sprintf("%d", bidId),
				"bidder":  bidderAddress,
				"auction": fmt.Sprintf("%d", auctionId),
			}))

	})

	t.Run("Should get all bids with large number of bids", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "100000.0")

		auctionId := gwtfTest.setupDutchAuction()

		//TODO: increase this to test with large number of bids. I have tested with 10000, test timed out after 7800 :p
		//5000 bids suceeds
		maxNumber := 100
		number := 0
		var bidNumber uint64
		bidNumber = 69
		for ; number < maxNumber; number++ {
			gwtfTest.dutchBid("buyer1", auctionId, "5.0", bidNumber)
			bidNumber = bidNumber + 2
		}
		bids, err := gwtfTest.GWTF.ScriptFromFile("dutchAuctionBidReport").UInt64Argument(auctionId).RunReturns()
		assert.NoError(gwtfTest.T, err)
		assert.Equal(gwtfTest.T, maxNumber, len(bids.(cadence.Array).Values))

	})
	t.Run("Should get all bids even bids not winning", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "1000.0")

		auctionId := gwtfTest.setupDutchAuction()

		gwtfTest.dutchBid("buyer1", auctionId, "9.0", 69)
		gwtfTest.dutchBid("buyer1", auctionId, "9.2", 71)
		gwtfTest.dutchBid("buyer1", auctionId, "5.0", 73)
		gwtfTest.dutchBid("buyer1", auctionId, "4.0", 75)
		gwtfTest.dutchBid("buyer1", auctionId, "9.0", 77)
		gwtfTest.dutchBid("buyer1", auctionId, "8.0", 79)
		gwtfTest.dutchBid("buyer1", auctionId, "2.0", 81)
		gwtfTest.dutchBid("buyer1", auctionId, "1.0", 83)
		gwtfTest.dutchBid("buyer1", auctionId, "1.0", 85)
		gwtfTest.dutchBid("buyer1", auctionId, "1.0", 87)
		gwtfTest.dutchBid("buyer1", auctionId, "1.0", 89)
		gwtfTest.dutchBid("buyer1", auctionId, "9.0", 91)

		expectedBids := `{
    "bids": [
      {
	       "amount": "9.20000000",
	       "bidder": "0x179b6b1cb6755e31",
	       "confirmed": "false",
	       "id": "71",
	       "time": "1.00000000",
	       "winning": "true"
	   }, 
     {
         "amount": "9.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "69",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "9.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "77",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "9.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "91",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "8.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "79",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "5.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "73",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "4.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "75",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "2.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "81",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "1.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "83",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "1.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "85",
         "time": "1.00000000",
         "winning": "true"
     },
     {
         "amount": "1.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "87",
         "time": "1.00000000",
         "winning": "false"
     },
     {
         "amount": "1.00000000",
         "bidder": "0x179b6b1cb6755e31",
         "confirmed": "false",
         "id": "89",
         "time": "1.00000000",
         "winning": "false"
     }
  ],
  "winningPrice": "1.00000000"
}`
		bids := gwtfTest.auctionBids(auctionId)
		assert.JSONEq(gwtfTest.T, expectedBids, bids)

	})

	/*
		t.Run("Should be able to cancel bid", func(t *testing.T) {

			gwtfTest := NewGWTFTest(t).
				setup().
				createArtCollectionAndMintFlow("artist", "100.0").
				createArtCollectionAndMintFlow("buyer1", "100000.0")

			auctionId := gwtfTest.setupDutchAuction()
			gwtfTest.dutchBid("buyer1", auctionId, "1.0", 69).tickClock("2.0")

			value := gwtfTest.GWTF.ScriptFromFile("dutchAuctionUserBid").AccountArgument("buyer1").RunReturnsJsonString()
			output := `[
			    {
			        "excessAmount": "0.00000000",
			        "id": "95",
			        "winning": "false"
			    }
			]`

			assert.Equal(gwtfTest.T, output, value)

			gwtfTest.GWTF.TransactionFromFile("dutchBidCancel").SignProposeAndPayAs("buyer1").UInt64Argument(69).Test(gwtfTest.T).AssertSuccess()

		})
	*/
}
