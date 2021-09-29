package main

import (
	"math/rand"
	"time"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
)

func main() {
	g := gwtf.NewGoWithTheFlowMainNet()

	accounts := []string{
		"0xa9a82c6a04d6df2b",
		"0x01d63aa89238a559",
		"0x53f389d96fb4ce5e",
		"0x886f3aeaf848c535",
		"0x1ad314a2f884cd63",
		"0x1ad314a2f884cd63",
		"0x3f108fd8f4ccfc09",
		"0x77b78d7d3f0d1787",
		"0xdd718b0856a69974",
		"0xd9d9f9b6a0f26d4a",
		"0xe06a1f687b5e251a",
	}

	rand.Seed(time.Now().UnixNano())
	rand.Shuffle(len(accounts), func(i, j int) { accounts[i], accounts[j] = accounts[j], accounts[i] })

	var addresses []cadence.Value
	for _, key := range accounts {
		address := cadence.BytesToAddress(flow.HexToAddress(key).Bytes())
		addresses = append(addresses, address)
	}
	cadenceArray := cadence.NewArray(addresses)

	err := g.DownloadImageAndUploadAsDataUrl("https://uploads.linear.app/b5013517-8161-4940-b2a0-d5fc21b1fafb/04e6f85d-3ab6-4380-8886-b56038f2978c/7c165eae-5eaa-4c5d-a9f0-69d6522d69b7", "admin")
	if err != nil {
		panic(err)
	}

	g.TransactionFromFile("mint_art_e").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0x518c0a772d80d241").
		StringArgument("Ben Mauro").
		StringArgument("B-23 CHIMP"). //artist name
		StringArgument(`C.H.I.M.P. support robot. A soldiers best companion on the battlefield.`).
		Argument(cadenceArray).
		RunPrintEventsFull()

}
