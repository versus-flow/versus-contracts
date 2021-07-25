package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"math"
	"net/http"
	"os"
	"time"

	"github.com/araddon/dateparse"
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

func parseTime(timeString string) string {
	loc, err := time.LoadLocation("America/New_York")
	if err != nil {
		panic(err)
	}

	time.Local = loc
	t, err := dateparse.ParseLocal(timeString)
	if err != nil {
		panic(err)
	}

	unix := t.Unix()

	time := fmt.Sprintf("%d.0", unix)
	return time
}

func main() {

	startDate := "July 29"
	durationHrs := 4
	artistAddress := "0x1b945b52f416ddf9"
	artist := "Jos"
	name := "Solitude 2.0"
	editions := 15
	description := `In the near future,
when we have conquered all
we will still be strangers to ourselves
We will bridge the open space
we will witness new wonders
but in the immense distance of the cosmos
we will be smaller and smaller."
`
	fileName := "solitude.jpeg"

	flow := gwtf.NewGoWithTheFlowDevNet()

	image, err := fileAsImageData(fileName)
	if err != nil {
		panic(err)
	}

	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("setup/upload").SignProposeAndPayAs("admin").StringArgument(part).RunPrintEventsFull()
	}

	flow.TransactionFromFile("setup/drop_prod").
		SignProposeAndPayAs("admin").
		RawAccountArgument(artistAddress).
		UFix64Argument("1.00").                                     //start price
		UFix64Argument(parseTime(startDate + ", 2021 8:00:00 AM")). //start time `date -r to confirm`
		StringArgument(artist).                                     //artist name
		StringArgument(name).                                       //name
		StringArgument(description).                                //description
		UInt64Argument(uint64(editions)).                           //number of editions
		UFix64Argument("2.0").                                      //min bid increment
		UFix64Argument("4.0").                                      //min bid increment unique
		UFix64Argument(fmt.Sprintf("%d.0", durationHrs*60*60)).     //duration 60 * 60 * 24 1 day
		UFix64Argument("300.0").                                    //extensionOnLateBid 5 * 60 5 min
		RunPrintEventsFull()

}
