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

		gwtfTest.dutchBid("buyer1", auctionId, "10.0", 1, 0, "10.00000000").tickClock("1.0")
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 2, 0, "8.95586981")
		gwtfTest.dutchBid("buyer2", auctionId, "9.0", 3, 1, "8.95586981")

	})

}
