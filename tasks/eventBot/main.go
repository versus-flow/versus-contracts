package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/bwmarrin/discordgo"
	"github.com/davecgh/go-spew/spew"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlowMainNet()

	//	g := gwtf.NewGoWithTheFlowDevNet()

	url, ok := os.LookupEnv("DISCORD_WEBHOOK_URL")
	if !ok {
		fmt.Println("webhook url is not present")
		os.Exit(1)
	}

	prefix := "https://www.versus.auction"

	imageThumNailPattern := "https://res.cloudinary.com/dxra4agvf/image/upload/v1629285775/maincache%s.jpg"

	bidEvent := "A.99ca04281098b33d.Versus.ExtendedBid"
	events, err := g.EventFetcher().
		TrackProgressIn(".flow-prod.eventBot").
		Workers(1).
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
	var embeds []*discordgo.MessageEmbed
	for _, event := range events {
		cacheKey := event.Fields["cacheKey"]

		price := strings.TrimSuffix(event.Fields["price"].(string), "000000") + " Flow"

		bidder := event.Fields["bidderAddress"]
		if event.Fields["bidderName"] != "" {
			bidder = event.Fields["bidderName"]
		}

		fields := map[string]interface{}{
			"bidder": fmt.Sprintf("[%s](%s/profiles/%s)", bidder, prefix, event.Fields["bidderAddress"]),
		}

		if event.Fields["oldBidderName"].(string) != "" {
			oldPrice := strings.TrimSuffix(event.Fields["oldPrice"].(string), "000000") + " Flow"
			oldBidder := event.Fields["oldBidderAddress"]
			if event.Fields["oldBidderName"] != "" {
				oldBidder = event.Fields["oldBidderName"]
			}
			fields["previousBid"] = fmt.Sprintf("%s by [%s](%s/profiles/%s)", oldPrice, oldBidder, prefix, event.Fields["oldBidderAddress"])
		}

		leader := event.Fields["newLeader"].(string)
		oldLeader := event.Fields["oldLeader"].(string)

		if leader != oldLeader {
			fields["leaderChanged"] = leader
		}

		endAt := event.Fields["auctionEndAt"].(string)
		if s, err := strconv.ParseFloat(endAt, 64); err == nil {
			endTime := time.Unix(int64(s), 0)
			fields["auctionEndAt"] = endTime
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

		//https://versusapptest.vercel.app/drop/5/#
		embeds = append(embeds, &discordgo.MessageEmbed{
			URL:    fmt.Sprintf("%s/drop/%s", prefix, event.Fields["dropId"]),
			Title:  fmt.Sprintf("bid on %s - %s by %s for %s!", event.Fields["edition"], event.Fields["name"], event.Fields["artist"], price),
			Type:   discordgo.EmbedTypeRich,
			Fields: mef,
			Thumbnail: &discordgo.MessageEmbedThumbnail{
				URL: fmt.Sprintf(imageThumNailPattern, cacheKey),
			},
			Footer: &discordgo.MessageEmbedFooter{
				Text: fmt.Sprintf("blockHeight %d @ %v", event.BlockHeight, event.Time),
			},
		})

	}
	if len(embeds) == 0 {
		os.Exit(0)
	}

	message := &discordgo.WebhookParams{
		Embeds: embeds,
	}

	spew.Dump(message)
	_, err = discord.WebhookExecute(
		dwh.ID,
		dwh.Token,
		dwh.Wait,
		message)

	if err != nil {
		panic(err)
	}
}
