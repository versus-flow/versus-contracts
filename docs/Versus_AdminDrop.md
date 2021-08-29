# Resource Interface `AdminDrop`

```cadence
resource interface AdminDrop {
}
```

## Functions

### fun `createDrop()`

```cadence
func createDrop(nft NonFungibleToken.NFT, editions UInt64, minimumBidIncrement UFix64, minimumBidUniqueIncrement UFix64, startTime UFix64, startPrice UFix64, vaultCap Capability<&{FungibleToken.Receiver}>, duration UFix64, extensionOnLateBid UFix64)
```

---

### fun `settle()`

```cadence
func settle(_ UInt64)
```

---
