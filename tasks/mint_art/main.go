package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	flow := gwtf.NewGoWithTheFlowMainNet()
	/*
		account, ok := os.LookupEnv("account")
		if !ok {
			fmt.Println("account is not present")
			os.Exit(1)
		}

			imageFile, ok := os.LookupEnv("image")
			if !ok {
				imageFile = "bull.png"
			}
	*/

	err := flow.UploadImageAsDataUrl("invasion.jpg", "admin")
	if err != nil {
		panic(err)
	}

	flow.TransactionFromFile("mint_art").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0xc0fbdb2a314f0ba9").
		StringArgument("MiraRuido"). //artist name
		StringArgument("Invasion").  //name of art
		StringArgument(`"Invasion" is the memory of an event that never happened, like the postcard you receive from a place that never existed. But if at some point on September 7, 1948, alien ships had attacked New York City to abduct its citizens, it might have looked like this.

This collage, composed of photographs and materials from different sources, is one of my best-known illustrations, and one of my best-selling prints with copies spread all over the world.`).
		RawAccountArgument("0x80cd9c6d1ff10590").
		RunPrintEventsFull()

}
