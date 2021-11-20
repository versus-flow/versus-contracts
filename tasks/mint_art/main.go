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
		AccountArgument("admin").
		StringArgument("Kinger999"). //artist name
		StringArgument("TheBull").   //name of art
		StringArgument(`The crypto bull`).
		RawAccountArgument(account).     //target
		StringArgument("image/dataurl"). //type
		UFix64Argument("0.05").          //artistCut 5%
		UFix64Argument("0.025").         //minterCut 2.5%
		RunPrintEventsFull()

}
