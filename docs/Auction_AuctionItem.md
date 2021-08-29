# Resource `AuctionItem`

```cadence
resource AuctionItem {

    numberOfBids:  UInt64

    NFT:  Art.NFT?

    bidVault:  FungibleToken.Vault

    auctionID:  UInt64

    minimumBidIncrement:  UFix64

    auctionStartTime:  UFix64

    auctionLength:  UFix64

    auctionCompleted:  Bool

    startPrice:  UFix64

    currentPrice:  UFix64

    recipientCollectionCap:  Capability<&{Art.CollectionPublic}>?

    recipientVaultCap:  Capability<&{FungibleToken.Receiver}>?

    ownerCollectionCap:  Capability<&{Art.CollectionPublic}>

    ownerVaultCap:  Capability<&{FungibleToken.Receiver}>
}
```


### Initializer

```cadence
func init(NFT Art.NFT, minimumBidIncrement UFix64, auctionStartTime UFix64, startPrice UFix64, auctionLength UFix64, ownerCollectionCap Capability<&{Art.CollectionPublic}>, ownerVaultCap Capability<&{FungibleToken.Receiver}>)
```


## Functions

### fun `content()`

```cadence
func content(): String?
```

---

### fun `sendNFT()`

```cadence
func sendNFT(_ Capability<&{Art.CollectionPublic}>)
```

---

### fun `sendBidTokens()`

```cadence
func sendBidTokens(_ Capability<&{FungibleToken.Receiver}>)
```

---

### fun `releasePreviousBid()`

```cadence
func releasePreviousBid()
```

---

### fun `settleAuction()`

```cadence
func settleAuction(cutPercentage UFix64, cutVault Capability<&{FungibleToken.Receiver}>)
```

---

### fun `returnAuctionItemToOwner()`

```cadence
func returnAuctionItemToOwner()
```

---

### fun `timeRemaining()`

```cadence
func timeRemaining(): Fix64
```

---

### fun `isAuctionExpired()`

```cadence
func isAuctionExpired(): Bool
```

---

### fun `minNextBid()`

```cadence
func minNextBid(): UFix64
```

---

### fun `extendWith()`

```cadence
func extendWith(_ UFix64)
```

---

### fun `bidder()`

```cadence
func bidder(): Address?
```

---

### fun `currentBidForUser()`

```cadence
func currentBidForUser(address Address): UFix64
```

---

### fun `placeBid()`

```cadence
func placeBid(bidTokens FungibleToken.Vault, vaultCap Capability<&{FungibleToken.Receiver}>, collectionCap Capability<&{Art.CollectionPublic}>)
```

---

### fun `getAuctionStatus()`

```cadence
func getAuctionStatus(): AuctionStatus
```

---
