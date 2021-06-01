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

	image := fileAsImageData("zigor.jpg")

	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("setup/upload").SignProposeAndPayAs("admin").StringArgument(part).RunPrintEventsFull()
	}

	flow.TransactionFromFile("setup/drop_prod").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0xfb1b4662ca2f6dbd").
		UFix64Argument("1.00").                //start price
		UFix64Argument("1622642400.0").        //start time `date -r to confirm`
		StringArgument("Zigor"). //artist name
		StringArgument("Jaime el hortaliza").    //name
		StringArgument("Jaime is a peculiar guy, depending on the time of the day he is angry or very happy, or both at the same time. Not many people know it but Jaime has a split personality. Every once in a while a human eats him but sooner or later he comes out again.").
		UInt64Argument(10).        //number of editions
		UFix64Argument("2.0").     //min bid increment
		UFix64Argument("4.0").     //min bid increment unique
		UFix64Argument("86400.0"). //duration 60 * 60 * 24 1 day
		UFix64Argument("300.0").   //extensionOnLateBid 5 * 60 5 min
		RunPrintEventsFull()

}
