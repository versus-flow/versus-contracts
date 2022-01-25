package main

import (
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/bwmarrin/discordgo"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlowMainNet()

	url, ok := os.LookupEnv("DISCORD_WEBHOOK_URL")
	if !ok {
		fmt.Println("webhook url is not present")
		os.Exit(1)
	}

	prefix := "https://www.versus.auction"

	imageThumNailPattern := "https://res.cloudinary.com/dxra4agvf/image/upload/v1629285775/maincache%s.jpg"

	bidEvent := "A.d796ff17107bbff6.Versus.ExtendedBid"
	events, err := g.EventFetcher().
		TrackProgressIn(".flow-prod.eventBot").
		//Start(52749400).End(52749479).
		Workers(1).
		BatchSize(100).
		Event(bidEvent).
		Run()

	if err != nil {
		panic(err)
	}

	discord, err := discordgo.New()
	if err != nil {
		panic(err)
	}

	dwh := gwtf.NewDiscordWebhook(url)
	for _, event := range events {

		bidder := event.Fields["bidderAddress"]
		if event.Fields["bidderName"] != "" {
			bidder = event.Fields["bidderName"]
		}
		//TODO; remove in a while
		price := strings.TrimSuffix(event.Fields["price"].(string), "000000") + " Flow"
		fmt.Printf("Found bid by %s on %s for %s flow\n", bidder, event.Fields["edition"], price)
		cacheKey := event.Fields["cacheKey"]

		fields := map[string]interface{}{
			"bidder": fmt.Sprintf("[%s](%s/profile/%s)", bidder, prefix, event.Fields["bidderAddress"]),
			"bid":    price,
		}

		if event.Fields["oldBidderAddress"].(string) != "" {
			oldPrice := strings.TrimSuffix(event.Fields["oldPrice"].(string), "000000") + " Flow"
			oldBidder := event.Fields["oldBidderAddress"]
			if event.Fields["oldBidderName"] != "" {
				oldBidder = event.Fields["oldBidderName"]
			}
			fields["previousBid"] = fmt.Sprintf("%s by [%s](%s/profile/%s)", oldPrice, oldBidder, prefix, event.Fields["oldBidderAddress"])
		}

		endAt := event.Fields["auctionEndAt"].(string)
		if _, err := strconv.ParseFloat(endAt, 64); err == nil {
			if event.Fields["extendWith"] != "0.00000000" {
				fields["lateBidExtension"] = event.Fields["extendWith"]
			}
		}

		var mef []*discordgo.MessageEmbedField
		for name, value := range fields {
			mef = append(mef, &discordgo.MessageEmbedField{
				Name:  name,
				Value: fmt.Sprintf("%v", value),
			})
		}

		sort.SliceStable(mef, func(i, j int) bool {
			return mef[i].Name < mef[j].Name
		})

		embed := &discordgo.MessageEmbed{
			URL:    fmt.Sprintf("%s/drop/%s", prefix, event.Fields["dropId"]),
			Title:  fmt.Sprintf("bid on %s - %s by %s!", event.Fields["edition"], event.Fields["name"], event.Fields["artist"]),
			Type:   discordgo.EmbedTypeRich,
			Fields: mef,
			Thumbnail: &discordgo.MessageEmbedThumbnail{
				URL: fmt.Sprintf(imageThumNailPattern, cacheKey),
			},
			Footer: &discordgo.MessageEmbedFooter{
				Text: fmt.Sprintf("blockHeight %d @ %v", event.BlockHeight, event.Time),
			},
		}
		message := &discordgo.WebhookParams{
			Embeds: []*discordgo.MessageEmbed{embed},
		}

		_, err = discord.WebhookExecute(
			dwh.ID,
			dwh.Token,
			dwh.Wait,
			message)

		if err != nil {
			fmt.Printf("%v\n", err)
			panic(err)
		}
	}
}
