package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
)

func main() {
	g := gwtf.NewGoWithTheFlowMainNet()

	accounts := []string{
		"0x80cd9c6d1ff10590",
	}

	var addresses []cadence.Value
	for _, key := range accounts {
		address := cadence.BytesToAddress(flow.HexToAddress(key).Bytes())
		addresses = append(addresses, address)
	}
	cadenceArray := cadence.NewArray(addresses)

	err := g.DownloadImageAndUploadAsDataUrl("https://uploads.linear.app/b5013517-8161-4940-b2a0-d5fc21b1fafb/6af7763b-4be5-4d74-8c16-206e42035ed7/70971e15-6e47-4f0e-bf31-07d2fed8c3fb", "admin")
	if err != nil {
		panic(err)
	}

	g.TransactionFromFile("mint_art_e").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0x38bcc76e9e4f9a7c").
		StringArgument("Bryan Brinkman").
		StringArgument("Cloudy Thoughts"). //artist name
		StringArgument(`An explosion of ideas, built on past creations with references to “Explode”, “Wired”, “Overcast” and “NimBuds”.`).
		Argument(cadenceArray).
		RunPrintEventsFull()

}
