package main

import (
	"bufio"
	"encoding/base64"
	"io/ioutil"
	"math"
	"net/http"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

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

	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("setup/upload.cdc").SignProposeAndPayAs("marketplace").StringArgument(part)
	}

	flow.TransactionFromFile("setup/drop_testnet").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0xd21cfcf820f27c42").
		UFix64Argument("1.00").          //start price
		UFix64Argument(timeString).      //start time
		StringArgument("ekaitza").       //artist name
		StringArgument("Transcendence"). //name
		StringArgument("We are complex individuals that have to often pull from our strengths and weaknesses in order to transcend. 3500x 3500 pixels, rendered at 350 ppi").
		Argument(cadence.NewUInt64(15)). //number of editions to use for the editioned auction
		UFix64Argument("2.0").           //min bid increment
		UFix64Argument("4.0").           //min bid increment unique
		UFix64Argument("86400.0").       //duration 60 * 60 * 24 1 day
		UFix64Argument("600.0").         //extensionOnLateBid 10 * 60 10 min
		RunPrintEventsFull()

}
