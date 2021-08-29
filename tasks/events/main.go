package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlowMainNet()

	url, ok := os.LookupEnv("DISCORD_WEBHOOK_URL")
	if !ok {
		fmt.Println("webhook url is not present")
		os.Exit(1)
	}

	_, err := g.EventFetcher().
		Workers(1).
		TrackProgressIn(".flow-prod.events").
		EventIgnoringFields("A.d796ff17107bbff6.Versus.Bid", []string{"auctionId", "dropId"}).
		EventIgnoringFields("A.d796ff17107bbff6.Versus.LeaderChanged", []string{"dropId"}).
		Event("A.d796ff17107bbff6.Versus.Settle").
		RunAndSendToWebhook(url)

	if err != nil {
		panic(err)
	}

}
