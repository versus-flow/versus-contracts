package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlowMainNet()

	ev, err := g.EventFetcher().
		Workers(10).
		BatchSize(100).
		Start(20539021).
		Until(20541101).
		Event("A.d796ff17107bbff6.Versus.ExtendedBid").
		Run()

	if err != nil {
		panic(err)
	}
	for _, e := range ev {
		fmt.Printf("%v\n", e)
	}

	if err != nil {
		panic(err)
	}

}
