# Resource `DropCollection`

```cadence
resource DropCollection {

    drops:  {UInt64: Drop}

    cutPercentage:  UFix64

    marketplaceVault:  Capability<&{FungibleToken.Receiver}>

    marketplaceNFTTrash:  Capability<&{Art.CollectionPublic}>
}
```


Implemented Interfaces:
  - `PublicDrop`
  - `AdminDrop`


### Initializer

```cadence
func init(marketplaceVault Capability<&{FungibleToken.Receiver}>, marketplaceNFTTrash Capability<&{Art.CollectionPublic}>, cutPercentage UFix64)
```


## Functions

### fun `createDrop()`

```cadence
func createDrop(nft NonFungibleToken.NFT, editions UInt64, minimumBidIncrement UFix64, minimumBidUniqueIncrement UFix64, startTime UFix64, startPrice UFix64, vaultCap Capability<&{FungibleToken.Receiver}>, duration UFix64, extensionOnLateBid UFix64)
```

---

### fun `getAllStatuses()`

```cadence
func getAllStatuses(): {UInt64: DropStatus}
```

---

### fun `getDrop()`

```cadence
func getDrop(_ UInt64): &Drop
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

### fun `settle()`

```cadence
func settle(_ UInt64)
```

---

### fun `currentBidForUser()`

```cadence
func currentBidForUser(dropId UInt64, auctionId UInt64, address Address): UFix64
```

---

### fun `placeBid()`

```cadence
func placeBid(dropId UInt64, auctionId UInt64, bidTokens FungibleToken.Vault, vaultCap Capability<&{FungibleToken.Receiver}>, collectionCap Capability<&{Art.CollectionPublic}>)
```

---
