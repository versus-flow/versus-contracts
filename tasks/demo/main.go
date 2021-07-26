package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"math"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
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

//NB! start from root dir with makefile
func main() {

	now := time.Now()
	t := now.Unix() - 5
	timeString := strconv.FormatInt(t, 10) + ".0"

	flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("emulator-account").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("artist").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("marketplace").UFix64Argument("100.0").RunPrintEventsFull()

	//create the AdminPublicAndSomeOtherCollections
	flow.TransactionFromFile("versus1").
		SignProposeAndPayAs("marketplace").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("versus2").
		SignProposeAndPayAsService().
		AccountArgument("marketplace").
		RunPrintEventsFull()

	fmt.Println("try to upload")

	image := fileAsImageData("ekaitza.png")
	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		flow.TransactionFromFile("upload").SignProposeAndPayAs("marketplace").StringArgument(part).RunPrintEventsFull()
	}
	fmt.Println("Create a drop in versus that is already started with 10 editions")
	flow.TransactionFromFile("drop").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").                                                                      //marketplace location
		UFix64Argument("10.00").                                                                        //start price
		UFix64Argument(timeString).                                                                     //start time
		StringArgument("Vincent Kamp").                                                                 //artist name
		StringArgument("when?").                                                                        //name of art
		StringArgument("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"). //description
		Argument(cadence.NewUInt64(10)).                                                                //number of editions to use for the editioned auction
		UFix64Argument("5.0").                                                                          //min bid increment
		UFix64Argument("10.0").                                                                         //min bid increment unique
		UFix64Argument("5.0").                                                                          //duration
		RunPrintEventsFull()

	fmt.Println("Setup a buyer and make him bid on the unique auction")
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer1").UFix64Argument("1000.0").RunPrintEventsFull()

	flow.TransactionFromFile("bid").
		SignProposeAndPayAs("buyer1").
		RawAccountArgument("0xf8d6e0586b0a20c7"). //we use raw argument here because of a limitation on how go-with-the-flow is built
		UInt64Argument(1).                        //id of drop
		Argument(cadence.UInt64(11)).             //id of unique auction auction to bid on
		UFix64Argument("10.00").                  //amount to bid
		RunPrintEventsFull()

	flow.TransactionFromFile("bid").
		SignProposeAndPayAs("buyer1").
		RawAccountArgument("0xf8d6e0586b0a20c7"). //we use raw argument here because of a limitation on how go-with-the-flow is built
		UInt64Argument(1).                        //id of drop
		Argument(cadence.UInt64(11)).             //id of unique auction auction to bid on
		UFix64Argument("30.00").                  //amount to bid
		RunPrintEventsFull()

	fmt.Println("Go to website to bid there")
	fmt.Println("Tick the clock to make the auction end and settle it")
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	fmt.Println("settle")

	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").UInt64Argument(1).Run()
	flow.TransactionFromFile("settle").SignProposeAndPayAs("marketplace").UInt64Argument(1).RunPrintEventsFull()

	flow.ScriptFromFile("check_account").AccountArgument("buyer1").Run()
	flow.ScriptFromFile("check_account").AccountArgument("buyer2").Run()
	flow.ScriptFromFile("check_account").AccountArgument("artist").Run()
	flow.ScriptFromFile("check_account").AccountArgument("marketplace").Run()

	flow.ScriptFromFile("drop_status").UInt64Argument(1).Run()
	flow.TransactionFromFile("destroy_versus").SignProposeAndPayAsService().UInt64Argument(1).RunPrintEventsFull()
}
