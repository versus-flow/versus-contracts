package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlow(".flow-prod.json")

	//fetch the current block height
	eb := g.SendEventsTo("versus-prod").
		TrackProgressIn(".flow-prod.events").
		EventIgnoringFields("A.d796ff17107bbff6.Versus.Bid", []string{"auctionId", "dropId"}).
		EventIgnoringFields("A.d796ff17107bbff6.Versus.LeaderChanged", []string{"dropId"}).
		Event("A.d796ff17107bbff6.Versus.Settle")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
