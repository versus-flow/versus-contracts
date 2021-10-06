package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
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

		gwtfTest.dutchBid("buyer1", auctionId, "10.0", 1, 0, "10.00000000", "smallest", 1).tickClock("2.0")
		gwtfTest.dutchTickNotFullfilled(auctionId, 1, "9.00000000", "3.0")
		expectedStatus := `A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionStatus(status: \"Finished\", startTime: 1.00000000, currentTime: 6.00000000, currentPrice: 9.00000000, totalItems: 10, acceptedBids: 10, tickStatus: {1.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 10.00000000, startedAt: 1.00000000, acceptedBids: 1, cumulativeAcceptedBids: 1), 3.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 9.00000000, startedAt: 3.00000000, acceptedBids: 9, cumulativeAcceptedBids: 10)}, metadata: {\"nftType\": \"A.f8d6e0586b0a20c7.Art.NFT\", \"name\": \"BULL\", \"artist\": \"Kinger9999\", \"artistAddress\": \"0x1cf0e2f2f715450\", \"description\": \"Teh bull\", \"type\": \"type\", \"contentId\": \"0\", \"url\": \"\"})`

		assert.Equal(gwtfTest.T, expectedStatus, gwtfTest.auctionStatus(auctionId))

		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 2, 0, "9.00000000", "smallest", 1)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 3, 1, "9.00000000", "smallest", 2)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 4, 2, "9.00000000", "smallest", 3)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 5, 3, "9.00000000", "smallest", 4)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 6, 4, "9.00000000", "smallest", 5)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 7, 5, "9.00000000", "smallest", 6)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 8, 6, "9.00000000", "smallest", 7)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 9, 7, "9.00000000", "smallest", 8)
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 10, 8, "9.00000000", "smallest", 9)
		gwtfTest.tickClock("3.0")
		gwtfTest.dutchTickFullfilled(auctionId, "9.00000000")

		expectedStatus = `A.f8d6e0586b0a20c7.DutchAuction.DutchAuctionStatus(status: \"Finished\", startTime: 1.00000000, currentTime: 6.00000000, currentPrice: 9.00000000, totalItems: 10, acceptedBids: 10, tickStatus: {1.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 10.00000000, startedAt: 1.00000000, acceptedBids: 1, cumulativeAcceptedBids: 1), 3.00000000: A.f8d6e0586b0a20c7.DutchAuction.TickStatus(price: 9.00000000, startedAt: 3.00000000, acceptedBids: 9, cumulativeAcceptedBids: 10)}, metadata: {\"nftType\": \"A.f8d6e0586b0a20c7.Art.NFT\", \"name\": \"BULL\", \"artist\": \"Kinger9999\", \"artistAddress\": \"0x1cf0e2f2f715450\", \"description\": \"Teh bull\", \"type\": \"type\", \"contentId\": \"0\", \"url\": \"\"})`

		assert.Equal(gwtfTest.T, expectedStatus, gwtfTest.auctionStatus(auctionId))

	})

	t.Run("Should insert bids that are greater before a smaller bid", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "100.0").
			createArtCollectionAndMintFlow("buyer2", "100.0")

		auctionId := gwtfTest.setupDutchAuction()

		gwtfTest.dutchBid("buyer1", auctionId, "9.8", 1, 0, "9.00000000", "smallest", 1)
		gwtfTest.dutchBid("buyer2", auctionId, "9.9", 2, 0, "9.00000000", "larger", 2)
	})

	t.Run("Should return cash if you bid more then roof", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("buyer1", "100.0")

		bidderAddress := fmt.Sprintf("0x%s", gwtfTest.GWTF.Account("buyer1").Address().String())
		auctionId := gwtfTest.setupDutchAuction()
		amount := "11.0"
		gwtfTest.GWTF.TransactionFromFile("dutchBid").
			SignProposeAndPayAs("buyer1").
			AccountArgument("account").
			UInt64Argument(auctionId). //id of auction
			UFix64Argument(amount).    //amount to bid
			Test(gwtfTest.T).AssertSuccess().
			AssertDebugLog("Bid smallest index=0 amount=10.00000000 tick=10.00000000 bidder=0x179b6b1cb6755e31 bidid=1 bidSize=1").
			AssertEmitEvent(gwtf.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": "1.00000000",
				"to":     bidderAddress,
			}))

	})

}
