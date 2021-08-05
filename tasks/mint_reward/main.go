package main

import (
	"bufio"
	"encoding/base64"
	"io/ioutil"
	"math"
	"net/http"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
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
	g := gwtf.NewGoWithTheFlowDevNet()

	accounts := []string{
		"0xf6337be8d00d3950",
		"0x97f01799da0472e6",
		"0xdd75ed85980ef5a8",
		"0x626e2a193431984d",
		"0xd094671f2eb0239b",
		"0x049dd9ad857ec93f",
		"0x8c17db6465f5406c",
		"0xc48a10eadb0ed1dc",
		"0xd33a7339beeda712",
		"0x7aad8cbf4bf09a9c",
		"0xc366b48b6ec6fdce",
		"0xbe597dbd64919901",
		"0x27371ae354486de0",
		"0x53f389d96fb4ce5e",
		"0x8a62bcb61681ef66",
		"0x2e5de12450d63ce8",
		"0xf44b810a228fecc0",
		"0x8ea4f41ce22217ab",
		"0xc9656a158cba99ef",
		"0x1052aecb4ac51547",
		"0xdbc15039ca69fbb2",
		"0xf16b42dcb3cf14ce",
		"0xb906e857f1f40f37",
		"0x29402ffede5845ed",
		"0x7294516ad0534ada",
		"0xb1c58f1f3236823f",
		"0xb93a257b93af195c",
		"0x2dfc0ed9e607f93f",
		"0xa2cd327adac6f564",
		"0x886f3aeaf848c535",
		"0xc641e1070ffdb0aa",
		"0x9a41084e8ea7693e",
		"0x01d63aa89238a559",
		"0x32c7b06ef9b0340f",
		"0x14c6ff4e7389da6a",
		"0x8b97f308a09c43be",
		"0x6832ece4728d0a5d",
		"0x7fc910a18d42360e",
		"0x04ff3cd96f31a964",
		"0xc38748bc281b53b0",
		"0x7e8c9fbd93d77f23",
		"0x5ea04e82b3fe560e",
		"0x08a2a687e7b9c0a5",
		"0x3f98df5e1be53c14",
		"0xb125acfa438a075f",
		"0x796b9c0ec8e77071",
		"0xbfeb3f852b1b3637",
		"0xf4ba72ad622d684c",
		"0xf1da2ba6170f775b",
		"0x0c0096bdcea83207",
		"0x4d433aa04f49a2ae",
		"0xd74a89c395f6acfb",
		"0x807f3f44833eb171",
		"0x80cd9c6d1ff10590",
		"0x81f33c32811df227",
		"0x4df4f44581d07237",
		"0x2b329798f39f96e1",
		"0x80cd9c6d1ff10590",
		"0xb5b47f5a33250715",
		"0x80cd9c6d1ff10590",
		"0xf6cd72955badad1f",
		"0xf391452a31ec7b3a",
		"0x327d45bc03a2fc7f",
		"0xcd19a0990fd4824b",
		"0x3c3715ab5157c21e",
		"0x80cd9c6d1ff10590",
		"0x0e4b5aa878fdb0a2",
		"0x5d28e0189e1ee640",
		"0x7a9a332cda3a0a6a",
		"0xe4d3f01b6c6f22e9",
		"0x63d53465376ec529",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
		"0x80cd9c6d1ff10590",
	}

	adminAddress := cadence.BytesToAddress(flow.HexToAddress("0x80cd9c6d1ff10590").Bytes())

	var addresses []cadence.Value
	for _, key := range accounts {
		address := cadence.BytesToAddress(flow.HexToAddress(key).Bytes())
		bool := g.ScriptFromFile("check_art").Argument(address).RunReturns()
		if bool.ToGoValue() == true {
			addresses = append(addresses, address)
		} else {
			addresses = append(addresses, adminAddress)
		}
	}
	cadenceArray := cadence.NewArray(addresses)

	image := fileAsImageData("versus.png")
	parts := splitByWidthMake(image, 1_000_000)
	for _, part := range parts {
		g.TransactionFromFile("upload").SignProposeAndPayAs("admin").StringArgument(part).RunPrintEventsFull()
	}

	g.TransactionFromFile("mint_art_e").
		SignProposeAndPayAs("admin").
		RawAccountArgument("0xd796ff17107bbff6").
		StringArgument("Versus"). //artist name
		StringArgument("VS").     //name of art
		StringArgument("This NFT was distributed to beta testers of the Versus platform as a reward for their invaluable feedback!").
		StringArgument("flow").
		UFix64Argument("0.05").  //artistCut 5%
		UFix64Argument("0.025"). //minterCut 2.5%
		Argument(cadenceArray).
		RunPrintEventsFull()

}
