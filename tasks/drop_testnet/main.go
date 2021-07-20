package main

import (
	"bufio"
	"encoding/base64"
	"io/ioutil"
	"math"
	"net/http"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
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

func fileAsImageData(path string) (string, error) {
	f, _ := os.Open("./" + path)

	defer f.Close()

	// Read entire JPG into byte slice.
	reader := bufio.NewReader(f)
	content, err := ioutil.ReadAll(reader)
	if err != nil {
		return "", err
	}

	contentType := http.DetectContentType(content)

	// Encode as base64.
	encoded := base64.StdEncoding.EncodeToString(content)

	return "data:" + contentType + ";base64, " + encoded, nil
}

func main() {
	flow := gwtf.NewGoWithTheFlowDevNet()

	image, err := fileAsImageData("sprinklefest.gif")
	if err != nil {
		panic(err)
	}

	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("upload").SignProposeAndPayAs("admin").StringArgument(part).RunPrintEventsFull()
	}

	flow.TransactionFromFile("drop_testnet").
		SignProposeAndPayAs("admin").
		AccountArgument("artist").
		UFix64Argument("1.00").         //start price
		UFix64Argument("1624565506.0"). //start time
		StringArgument("Sprinkler").   //artist name
		StringArgument("Sprinklefest").         //name
		StringArgument("PARTAYl").
		UInt64Argument(10).           //number of editions
		UFix64Argument("2.0").        //min bid increment
		UFix64Argument("4.0").        //min bid increment unique
		UFix64Argument("31536000.0"). //duration 60 * 60 * 24 1 day
		UFix64Argument("600.0").      //extensionOnLateBid 10 * 60 7.5 min
		RunPrintEventsFull()

}
