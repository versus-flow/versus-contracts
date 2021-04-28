package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlow(".flow-dev.json")

	//fetch the current block height
	eb := g.SendEventsTo("beta").
		TrackProgressIn(".flow-dev.events").
		EventIgnoringFields("A.d796ff17107bbff6.Versus.Bid", []string{"auctionId", "dropId"}).
		EventIgnoringFields("A.d796ff17107bbff6.Versus.LeaderChanged", []string{"dropId"}).
		Event("A.d796ff17107bbff6.Versus.Settle")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
