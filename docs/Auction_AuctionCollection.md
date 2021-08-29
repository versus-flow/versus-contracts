# Resource `AuctionCollection`

```cadence
resource AuctionCollection {

    auctionItems:  {UInt64: AuctionItem}

    cutPercentage:  UFix64

    marketplaceVault:  Capability<&{FungibleToken.Receiver}>
}
```


Implemented Interfaces:
  - `AuctionPublic`


### Initializer

```cadence
func init(marketplaceVault Capability<&{FungibleToken.Receiver}>, cutPercentage UFix64)
```


## Functions

### fun `extendAllAuctionsWith()`

```cadence
func extendAllAuctionsWith(_ UFix64)
```

---

### fun `keys()`

```cadence
func keys(): [UInt64]
```

---

### fun `createAuction()`

```cadence
func createAuction(token Art.NFT, minimumBidIncrement UFix64, auctionLength UFix64, auctionStartTime UFix64, startPrice UFix64, collectionCap Capability<&{Art.CollectionPublic}>, vaultCap Capability<&{FungibleToken.Receiver}>)
```

---

### fun `getAuctionStatuses()`

```cadence
func getAuctionStatuses(): {UInt64: AuctionStatus}
```

---

### fun `getAuctionStatus()`

```cadence
func getAuctionStatus(_ UInt64): AuctionStatus
```

---

### fun `settleAuction()`

```cadence
func settleAuction(_ UInt64)
```

---

### fun `cancelAuction()`

```cadence
func cancelAuction(_ UInt64)
```

---

### fun `placeBid()`

```cadence
func placeBid(id UInt64, bidTokens FungibleToken.Vault, vaultCap Capability<&{FungibleToken.Receiver}>, collectionCap Capability<&{Art.CollectionPublic}>)
```

---
