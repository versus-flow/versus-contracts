# Struct `DropAuctionStatus`

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


### Initializer

```cadence
func init(_ Auction.AuctionStatus)
```


