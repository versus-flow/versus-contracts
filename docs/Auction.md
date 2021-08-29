# Contract `Auction`

```cadence
contract Auction {

    totalAuctions:  UInt64
}
```

## Interfaces
    
### resource interface `AuctionPublic`

```cadence
resource interface AuctionPublic {
}
```

[More...](Auction_AuctionPublic.md)

---
## Structs & Resources

### struct `AuctionStatus`

```cadence
struct AuctionStatus {

    id:  UInt64

    price:  UFix64

    bidIncrement:  UFix64

    bids:  UInt64

    active:  Bool

    timeRemaining:  Fix64

    endTime:  Fix64

    startTime:  Fix64

    metadata:  Art.Metadata?

    artId:  UInt64?

    owner:  Address

    leader:  Address?

    minNextBid:  UFix64

    completed:  Bool

    expired:  Bool
}
```

[More...](Auction_AuctionStatus.md)

---

### resource `AuctionItem`

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

[More...](Auction_AuctionItem.md)

---

### resource `AuctionCollection`

```cadence
resource AuctionCollection {

    auctionItems:  {UInt64: AuctionItem}

    cutPercentage:  UFix64

    marketplaceVault:  Capability<&{FungibleToken.Receiver}>
}
```

[More...](Auction_AuctionCollection.md)

---
## Functions

### fun `createStandaloneAuction()`

```cadence
func createStandaloneAuction(token Art.NFT, minimumBidIncrement UFix64, auctionLength UFix64, auctionStartTime UFix64, startPrice UFix64, collectionCap Capability<&{Art.CollectionPublic}>, vaultCap Capability<&{FungibleToken.Receiver}>): AuctionItem
```

---

### fun `createAuctionCollection()`

```cadence
func createAuctionCollection(marketplaceVault Capability<&{FungibleToken.Receiver}>, cutPercentage UFix64): AuctionCollection
```

---
## Events

### event `TokenPurchased`

```cadence
event TokenPurchased(id UInt64, artId UInt64, price UFix64, from Address, to Address?)
```

---

### event `CollectionCreated`

```cadence
event CollectionCreated(owner Address, cutPercentage UFix64)
```

---

### event `Created`

```cadence
event Created(tokenID UInt64, owner Address, startPrice UFix64, startTime UFix64)
```

---

### event `Bid`

```cadence
event Bid(tokenID UInt64, bidderAddress Address, bidPrice UFix64)
```

---

### event `Settled`

```cadence
event Settled(tokenID UInt64, price UFix64)
```

---

### event `Canceled`

```cadence
event Canceled(tokenID UInt64)
```

---

### event `MarketplaceEarned`

```cadence
event MarketplaceEarned(amount UFix64, owner Address)
```

---
