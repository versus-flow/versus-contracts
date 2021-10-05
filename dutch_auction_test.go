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

		gwtfTest.dutchBid("buyer1", auctionId, "10.0", 1, 0, "10.00000000", "smallest", 1).tickClock("2.0")

		gwtfTest.dutchTickNotFullfilled(auctionId, 1, "9.00000000", "3.0")

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

	})

}
