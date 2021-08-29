# Struct `DropStatus`

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


### Initializer

```cadence
func init(dropId UInt64, uniqueStatus Auction.AuctionStatus, editionsStatuses {UInt64: DropAuctionStatus}, editionPrice UFix64, status String, firstBidBlock UInt64?, difference UFix64, metadata Art.Metadata, settledAt UInt64?, active Bool, startPrice UFix64)
```


