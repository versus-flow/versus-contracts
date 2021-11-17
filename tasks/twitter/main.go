package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/coreos/pkg/flagutil"
	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
)

type Tweet struct {
	message   string
	imageName string
	imageUrl  string
}

func main() {

	g := gwtf.NewGoWithTheFlowMainNet()

	purchaseEvent := "A.d796ff17107bbff6.Marketplace.TokenPurchased"
	saleEvent := "A.d796ff17107bbff6.Marketplace.SaleItem"
	events, err := g.EventFetcher().
		From(20298360).
		UntilCurrent().
		//	TrackProgressIn(".flow-prod.marketplaceEvents").
		Workers(10).
		Event(saleEvent).
		Event(purchaseEvent).Run()
	if err != nil {
		log.Fatal(err)
	}

	imageThumNailPattern := "https://res.cloudinary.com/dxra4agvf/image/upload/w_600/v1629285775/maincache%s.jpg"
	var messages []Tweet
	for _, pe := range events {

		if pe.Name == purchaseEvent {
			for _, se := range events {
				if se.Name == saleEvent && pe.BlockHeight == se.BlockHeight && pe.Fields["id"] == se.Fields["id"] && se.Fields["active"] == "false" {

					cacheKey := se.Fields["cacheKey"]

					price := strings.TrimSuffix(pe.Fields["price"].(string), "000000") + " Flow"
					profileFormat := "https://www.versus.auction/profile/%s/"

					to := fmt.Sprintf(profileFormat, pe.Fields["to"])
					from := fmt.Sprintf(profileFormat, se.Fields["seller"])
					artistHashtag := strings.ReplaceAll(se.Fields["artist"].(string), " ", "")
					message := fmt.Sprintf("%s by %s (%s of %s) sold from %s to %s for %s #versus #secondary #%s", se.Fields["title"], se.Fields["artist"], se.Fields["edition"], se.Fields["maxEdition"], from, to, price, artistHashtag)
					tweet := Tweet{
						message:   message,
						imageName: fmt.Sprintf("%s by %s", se.Fields["title"], se.Fields["artist"]),
						imageUrl:  fmt.Sprintf(imageThumNailPattern, cacheKey),
					}

					messages = append(messages, tweet)
				}
			}
		}
	}
	if len(messages) == 0 {
		os.Exit(0)
	}

	client := createTwitterClient()

	for _, tweet := range messages {

		content, err := getImage(tweet.imageUrl)
		if err != nil {
			log.Fatal(err)
		}
		//TODO: fix second param here it is mediaType
		media, _, err := client.Media.Upload(content, tweet.imageName)
		if err != nil {
			log.Fatal(err)
		}

		_, _, err = client.Statuses.Update(tweet.message, &twitter.StatusUpdateParams{
			MediaIds: []int64{media.MediaID},
		})
		if err != nil {
			log.Fatal(err)
		}
	}

}

func createTwitterClient() *twitter.Client {

	flags := flag.NewFlagSet("user-auth", flag.ExitOnError)
	consumerKey := flags.String("consumer-key", "", "Twitter Consumer Key")
	consumerSecret := flags.String("consumer-secret", "", "Twitter Consumer Secret")
	accessToken := flags.String("access-token", "", "Twitter Access Token")
	accessSecret := flags.String("access-secret", "", "Twitter Access Secret")
	flags.Parse(os.Args[1:])
	flagutil.SetFlagsFromEnv(flags, "TWITTER")

	if *consumerKey == "" || *consumerSecret == "" || *accessToken == "" || *accessSecret == "" {
		log.Fatal("Consumer key/secret and Access token/secret reuired")
	}

	config := oauth1.NewConfig(*consumerKey, *consumerSecret)
	token := oauth1.NewToken(*accessToken, *accessSecret)
	// OAuth1 http.Client will automatically authorize Requests
	httpClient := config.Client(oauth1.NoContext, token)

	// Twitter client
	client := twitter.NewClient(httpClient)
	return client
}

func getImage(uri string) ([]byte, error) {
	res, err := http.Get(uri)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()
	d, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatal(err)
	}
	return d, err
}
