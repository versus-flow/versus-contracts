package test_main

import (
	"testing"
)

func TestDutchAuction(t *testing.T) {

	t.Run("Should start and fullfill an auction", func(t *testing.T) {

		gwtfTest := NewGWTFTest(t).
			setup().
			createArtCollectionAndMintFlow("artist", "100.0").
			createArtCollectionAndMintFlow("buyer1", "100.0").
			createArtCollectionAndMintFlow("buyer2", "100.0")

		auctionId := gwtfTest.setupDutchAuction()

		gwtfTest.dutchBid("buyer1", auctionId, "10.0", 1, 0, "10.00000000").tickClock("2.0")

		gwtfTest.dutchTickNotFullfilled(auctionId, 1, "9.00000000", "3.0")

		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 2, 0, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 3, 1, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 4, 2, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 5, 3, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 6, 4, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 7, 5, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 8, 6, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 9, 7, "9.00000000")
    gwtfTest.dutchBid("buyer2", auctionId, "9.0", 10, 8, "9.00000000")
    gwtfTest.tickClock("3.0")
		gwtfTest.dutchTickNotFullfilled(auctionId, 1, "9.95000000", "3.0")

		
	})

}
