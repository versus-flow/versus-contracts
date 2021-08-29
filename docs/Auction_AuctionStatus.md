# Struct `AuctionStatus`

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


### Initializer

```cadence
func init(id UInt64, currentPrice UFix64, bids UInt64, active Bool, timeRemaining Fix64, metadata Art.Metadata?, artId UInt64?, leader Address?, bidIncrement UFix64, owner Address, startTime Fix64, endTime Fix64, minNextBid UFix64, completed Bool, expired Bool)
```


