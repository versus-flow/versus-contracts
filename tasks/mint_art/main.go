package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	flow := gwtf.NewGoWithTheFlowDevNet()

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}

	imageFile, ok := os.LookupEnv("image")
	if !ok {
		imageFile = "bull.png"
	}

	err := flow.UploadImageAsDataUrl(imageFile, "admin")
	if err != nil {
		panic(err)
	}

	flow.TransactionFromFile("mint_art").
		SignProposeAndPayAs("admin").
		RawAccountArgument(account).
		StringArgument("0xBjartek"). //artist name
		StringArgument(imageFile).   //name of art
		StringArgument("Randomly generated contourlines").
		RunPrintEventsFull()

}
