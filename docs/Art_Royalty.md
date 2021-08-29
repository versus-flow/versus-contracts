# Struct `Royalty`

```cadence
struct Royalty {

    wallet:  Capability<&{FungibleToken.Receiver}>

    cut:  UFix64
}
```


### Initializer

```cadence
func init(wallet Capability<&{FungibleToken.Receiver}>, cut UFix64)
```


