package main

import (
	"bufio"
	"encoding/base64"
	"encoding/hex"
	"io/ioutil"
	"math"
	"net/http"
	"os"
	"strings"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/davecgh/go-spew/spew"
	"github.com/onflow/cadence"
)

func fileAsImageData(path string) string {
	f, _ := os.Open("./" + path)

	defer f.Close()

	// Read entire JPG into byte slice.
	reader := bufio.NewReader(f)
	content, _ := ioutil.ReadAll(reader)

	contentType := http.DetectContentType(content)

	// Encode as base64.
	encoded := base64.StdEncoding.EncodeToString(content)

	return "data:" + contentType + ";base64, " + encoded
}

func splitByWidthMake(str string, size int) []string {
	strLength := len(str)
	splitedLength := int(math.Ceil(float64(strLength) / float64(size)))
	splited := make([]string, splitedLength)
	var start, stop int
	for i := 0; i < splitedLength; i += 1 {
		start = i * size
		stop = start + size
		if stop > strLength {
			stop = strLength
		}
		splited[i] = str[start:stop]
	}
	return splited
}

func main() {
	flow := gwtf.NewGoWithTheFlowDevNet()

	accounts := []string{"0xa92f1e2bb6978ff3",
		"0x7aad8cbf4bf09a9c",
		"0x3693303b2669856c",
		"0xcbdf19d61cc0eb80",
		"0x8bfc07b7d67d2396",
		"0x2e5de12450d63ce8",
		"0x0831b1aafba2a215",
		"0xab970f62ff24fd15",
		"0x32c7b06ef9b0340f",
		"0xa9cbc35e9fe9e649",
		"0xf6337be8d00d3950",
		"0xc51a17ff9c75f76a",
		"0x7c3639ec45bc7f6b",
		"0x886f3aeaf848c535",
		"0xdf868d4de6d2e0ab",
		"0x8971f163d111cfcd",
		"0xd7f7a6c5a26a725d",
		"0xc48a10eadb0ed1dc",
		"0x2f1a7a47f7db0fc8",
		"0x402e8631d876d85c",
		"0x99638805f4b51848",
		"0x48660ca71a35bede",
		"0xcdef88eb6f76418c",
		"0xcb25ee3bcfa29315",
		"0xa0fc96e34de16243",
		"0xc4363553c69a81b9",
		"0x2a0eccae942667be",
		"0x915cc83458eba23a",
		"0x92ba5cba77fc1e87",
		"0xcd321b69db46775d",
		"0x8b061fb31eaaf01c",
		"0x97db0e0fc558dece"}

	var addresses []cadence.Value
	for _, key := range accounts {
		trimmedString := strings.TrimPrefix(key, "0x")
		accountHex, err := hex.DecodeString(trimmedString)
		if err != nil {
			panic(err)
		}
		addresses = append(addresses, cadence.BytesToAddress(accountHex))
	}

	argument := cadence.NewArray(addresses)
	spew.Dump(argument)

	flow.ScriptFromFile("check_art").Argument(argument).RunReturns()

	image := fileAsImageData("percipient.png")
	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("setup/upload").SignProposeAndPayAs("admin").StringArgument(part).RunPrintEventsFull()
	}

	flow.TransactionFromFile("setup/mint_art_e").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0xd21cfcf820f27c42").
		StringArgument("ekaitza").    //artist name
		StringArgument("Percipient"). //name of art
		StringArgument("A percipient and clear-sighted mind is often rewarded. Founder’s NFT for Versus launch. 3500 x 3500 pixels. Rendered at 350 ppi.").
		Argument(argument).
		RunPrintEventsFull()

}
