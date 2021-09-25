# Resource Interface `PublicDrop`

```cadence
resource interface PublicDrop {
}
```

## Functions

### fun `currentBidForUser()`

```cadence
func currentBidForUser(dropId UInt64, auctionId UInt64, address Address): UFix64
```

---

### fun `getAllStatuses()`

```cadence
func getAllStatuses(): {UInt64: DropStatus}
```

---

### fun `getCacheKeyForDrop()`

```cadence
func getCacheKeyForDrop(_ UInt64): UInt64
```

---

### fun `getStatus()`

```cadence
func getStatus(dropId UInt64): DropStatus
```

---

### fun `getArt()`

```cadence
func getArt(dropId UInt64): String
```

---

### fun `placeBid()`

```cadence
func placeBid(dropId UInt64, auctionId UInt64, bidTokens FungibleToken.Vault, vaultCap Capability<&{FungibleToken.Receiver}>, collectionCap Capability<&{Art.CollectionPublic}>)
```

---
