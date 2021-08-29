# Resource Interface `AuctionPublic`

```cadence
resource interface AuctionPublic {
}
```

## Functions

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

### fun `placeBid()`

```cadence
func placeBid(id UInt64, bidTokens FungibleToken.Vault, vaultCap Capability<&{FungibleToken.Receiver}>, collectionCap Capability<&{Art.CollectionPublic}>)
```

---
