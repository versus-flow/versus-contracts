package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlowMainNet()

	url := "https://discord.com/api/webhooks/878741434595958824/BYFjKw9qh7SwXvWPPh8da5Yyt0alhwOyoeDEg0itGMsoD6JtW9pErQHu4YVaWdEa9vcH"

	//fetch the current block height

	_, err := g.EventFetcher().
		Workers(1).
		TrackProgressIn(".flow-prod.events").
		EventIgnoringFields("A.d796ff17107bbff6.Versus.Bid", []string{"auctionId", "dropId"}).
		EventIgnoringFields("A.d796ff17107bbff6.Versus.LeaderChanged", []string{"dropId"}).
		EventIgnoringFields("A.d796ff17107bbff6.Marketplace.SaleItem", []string{"cacheKey"}).
		EventIgnoringFields("A.d796ff17107bbff6.Marketplace.TokenPurchased", []string{"id"}).
		Event("A.d796ff17107bbff6.Versus.Settle").
		RunAndSendToWebhook(url)
	if err != nil {
		panic(err)
	}
}
