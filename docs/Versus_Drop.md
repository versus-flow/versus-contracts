# Resource `Drop`

```cadence
resource Drop {

    uniqueAuction:  Auction.AuctionItem

    editionAuctions:  Auction.AuctionCollection

    dropID:  UInt64

    firstBidBlock:  UInt64?

    settledAt:  UInt64?

    extensionOnLateBid:  UFix64

    metadata:  Art.Metadata

    contentId:  UInt64

    contentCapability:  Capability<&Content.Collection>
}
```


### Initializer

```cadence
func init(uniqueAuction Auction.AuctionItem, editionAuctions Auction.AuctionCollection, extensionOnLateBid UFix64, contentId UInt64, contentCapability Capability<&Content.Collection>)
```


## Functions

### fun `getContent()`

```cadence
func getContent(): String
```

---

### fun `getDropStatus()`

```cadence
func getDropStatus(): DropStatus
```

---

### fun `settle()`

```cadence
func settle(cutPercentage UFix64, vault Capability<&{FungibleToken.Receiver}>)
```

---

### fun `settleAllEditionedAuctions()`

```cadence
func settleAllEditionedAuctions()
```

---

### fun `cancelAllEditionedAuctions()`

```cadence
func cancelAllEditionedAuctions()
```

---

### fun `getAuction()`

```cadence
func getAuction(auctionId UInt64): &Auction.AuctionItem
```

---

### fun `currentBidForUser()`

```cadence
func currentBidForUser(auctionId UInt64, address Address): UFix64
```

---

### fun `placeBid()`

```cadence
func placeBid(auctionId UInt64, bidTokens FungibleToken.Vault, vaultCap Capability<&{FungibleToken.Receiver}>, collectionCap Capability<&{Art.CollectionPublic}>)
```

---

### fun `extendDropWith()`

```cadence
func extendDropWith(_ UFix64)
```

---
