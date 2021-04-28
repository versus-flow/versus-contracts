package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/bjartek/go-with-the-flow/gwtf"
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

func main() {
	flow := gwtf.NewGoWithTheFlowDevNet()

	timeString := "1619704800.0"
	image := fileAsImageData("ekaitza.png")

	flow.TransactionFromFile("setup/drop_testnet").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0xd21cfcf820f27c42").
		UFix64Argument("1.00").          //start price
		UFix64Argument(timeString).      //start time 
		StringArgument("ekaitza").       //artist name
		StringArgument("Transcendence"). //name
		StringArgument(image).           //image
		StringArgument("We are complex individuals that have to often pull from our strengths and weaknesses in order to transcend. 3500x 3500 pixels, rendered at 350 ppi").
		Argument(cadence.NewUInt64(15)). //number of editions to use for the editioned auction
		UFix64Argument("2.0").           //min bid increment
		UFix64Argument("4.0").           //min bid increment unique
		UFix64Argument("86400.0").       //duration 60 * 60 * 24 1 day
		UFix64Argument("600.0").         //extensionOnLateBid 10 * 60 10 min
		RunPrintEventsFull()

}
