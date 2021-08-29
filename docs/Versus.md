# Contract `Versus`

```cadence
contract Versus {

    VersusAdminPublicPath:  PublicPath

    VersusAdminStoragePath:  StoragePath

    CollectionStoragePath:  StoragePath

    CollectionPublicPath:  PublicPath

    CollectionPrivatePath:  PrivatePath

    totalDrops:  UInt64
}
```

## Interfaces
    
### resource interface `PublicDrop`

```cadence
resource interface PublicDrop {
}
```

[More...](Versus_PublicDrop.md)

---
    
### resource interface `AdminDrop`

```cadence
resource interface AdminDrop {
}
```

[More...](Versus_AdminDrop.md)

---
    
### resource interface `AdminPublic`

```cadence
resource interface AdminPublic {
}
```

[More...](Versus_AdminPublic.md)

---
## Structs & Resources

### resource `Drop`

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

[More...](Versus_Drop.md)

---

### struct `DropAuctionStatus`

```cadence
struct DropAuctionStatus {

    id:  UInt64

    price:  UFix64

    bidIncrement:  UFix64

    bids:  UInt64

    edition:  UInt64

    maxEdition:  UInt64

    leader:  Address?

    minNextBid:  UFix64
}
```

[More...](Versus_DropAuctionStatus.md)

---

### struct `DropStatus`

```cadence
struct DropStatus {

    dropId:  UInt64

    uniquePrice:  UFix64

    editionPrice:  UFix64

    difference:  UFix64

    endTime:  Fix64

    startTime:  Fix64

    uniqueStatus:  DropAuctionStatus

    editionsStatuses:  {UInt64: DropAuctionStatus}

    winning:  String

    active:  Bool

    timeRemaining:  Fix64

    firstBidBlock:  UInt64?

    metadata:  Art.Metadata

    expired:  Bool

    settledAt:  UInt64?

    startPrice:  UFix64
}
```

[More...](Versus_DropStatus.md)

---

### resource `DropCollection`

```cadence
resource DropCollection {

    drops:  {UInt64: Drop}

    cutPercentage:  UFix64

    marketplaceVault:  Capability<&{FungibleToken.Receiver}>

    marketplaceNFTTrash:  Capability<&{Art.CollectionPublic}>
}
```

[More...](Versus_DropCollection.md)

---

### resource `Admin`

```cadence
resource Admin {

    server:  Capability<&Versus.DropCollection>?
}
```

[More...](Versus_Admin.md)

---
## Functions

### fun `getArtForDrop()`

```cadence
func getArtForDrop(_ UInt64): String?
```

---

### fun `getDrops()`

```cadence
func getDrops(): [Versus.DropStatus]
```

---

### fun `getDrop()`

```cadence
func getDrop(_ UInt64): Versus.DropStatus?
```

---

### fun `getActiveDrop()`

```cadence
func getActiveDrop(): Versus.DropStatus?
```

---

### fun `createAdminClient()`

```cadence
func createAdminClient(): Admin
```

---
## Events

### event `DropExtended`

```cadence
event DropExtended(name String, artist String, dropId UInt64, extendWith Fix64, extendTo Fix64)
```

---

### event `Bid`

```cadence
event Bid(name String, artist String, edition String, bidder Address, price UFix64, dropId UInt64, auctionId UInt64)
```

---

### event `DropCreated`

```cadence
event DropCreated(name String, artist String, editions UInt64, owner Address, dropId UInt64)
```

---

### event `DropDestroyed`

```cadence
event DropDestroyed(dropId UInt64)
```

---

### event `Settle`

```cadence
event Settle(name String, artist String, winner String, price UFix64, dropId UInt64)
```

---

### event `LeaderChanged`

```cadence
event LeaderChanged(name String, artist String, winning String, dropId UInt64)
```

---
