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

	image := fileAsImageData("zebra_forrest.jpg")

	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("setup/upload").SignProposeAndPayAs("admin").StringArgument(part).RunPrintEventsFull()
	}

	flow.TransactionFromFile("setup/drop_testnet").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0x48660ca71a35bede").
		UFix64Argument("1.00").         //start price
		UFix64Argument("1620223200.0"). //start time
		StringArgument("Mankind").      //artist name
		StringArgument("Zebra Forest"). //name
		StringArgument("This yin and yang forest is visually in flux and balance at the same time. The striking landscape represents growth through competition versus going with the flow. The Versus innovative collector format and contrasting artwork show how seemingly opposite or contrary forces may actually be complementary and interconnected.").
		UInt64Argument(20).        //number of editions
		UFix64Argument("2.0").     //min bid increment
		UFix64Argument("4.0").     //min bid increment unique
		UFix64Argument("86400.0"). //duration 60 * 60 * 24 1 day
		UFix64Argument("450.0").   //extensionOnLateBid 10 * 60 7.5 min
		RunPrintEventsFull()

}
