package main

import (
	"fmt"
	"os"

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

	imageThumNailPattern := "https://res.cloudinary.com/dxra4agvf/image/upload/v1629285775/maincache%s.jpg"

	purchaseEvent := "A.d796ff17107bbff6.Marketplace.TokenPurchased"
	saleEvent := "A.d796ff17107bbff6.Marketplace.SaleItem"
	events, err := g.EventFetcher().
		TrackProgressIn(".flow-prod.metketplaceevents").
		Workers(1).
		Event(saleEvent).
		Event(purchaseEvent).Run()

	discord, err := discordgo.New()
	if err != nil {
		panic(err)
	}

	dwh := gwtf.NewDiscordWebhook(url)
	var embeds []*discordgo.MessageEmbed
	for _, pe := range events {

		if pe.Name == purchaseEvent {
			for _, se := range events {
				if se.Name == saleEvent && pe.BlockHeight == se.BlockHeight && pe.Fields["id"] == se.Fields["id"] && se.Fields["active"] == "false" {

					cacheKey := se.Fields["cacheKey"]
					fields := map[string]interface{}{
						"edition": fmt.Sprintf("%s of %s", se.Fields["edition"], se.Fields["maxEdition"]),
						"price":   pe.Fields["price"],
						"seller":  se.Fields["seller"],
						"buyer":   pe.Fields["to"],
					}
					var mef []*discordgo.MessageEmbedField
					for name, value := range fields {
						mef = append(mef, &discordgo.MessageEmbedField{
							Name:  name,
							Value: fmt.Sprintf("%v", value),
						})
					}

					embeds = append(embeds, &discordgo.MessageEmbed{
						URL:    fmt.Sprintf("https://www.versus.auction/piece/%s/%s/", fields["buyer"], pe.Fields["id"]),
						Title:  fmt.Sprintf("%s by %s sold!", se.Fields["title"], se.Fields["artist"]),
						Type:   discordgo.EmbedTypeRich,
						Fields: mef,
						Thumbnail: &discordgo.MessageEmbedThumbnail{
							URL: fmt.Sprintf(imageThumNailPattern, cacheKey),
						},
						Footer: &discordgo.MessageEmbedFooter{
							Text: fmt.Sprintf("blockHeight %d @ %s", se.BlockHeight, se.Time),
						},
					})

				}
			}
		}
	}
	if len(embeds) == 0 {
		os.Exit(0)
	}

	message := &discordgo.WebhookParams{
		Embeds: embeds,
	}

	_, err = discord.WebhookExecute(
		dwh.ID,
		dwh.Token,
		dwh.Wait,
		message)

	if err != nil {
		panic(err)
	}
}
