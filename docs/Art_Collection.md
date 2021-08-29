# Resource `Collection`

```cadence
resource Collection {

    ownedNFTs:  {UInt64: NonFungibleToken.NFT}
}
```


Implemented Interfaces:
  - `CollectionPublic`
  - `NonFungibleToken.Provider`
  - `NonFungibleToken.Receiver`
  - `NonFungibleToken.CollectionPublic`


### Initializer

```cadence
func init()
```


## Functions

### fun `withdraw()`

```cadence
func withdraw(withdrawID UInt64): NonFungibleToken.NFT
```

---

### fun `deposit()`

```cadence
func deposit(token NonFungibleToken.NFT)
```

---

### fun `getIDs()`

```cadence
func getIDs(): [UInt64]
```

---

### fun `borrowNFT()`

```cadence
func borrowNFT(id UInt64): &NonFungibleToken.NFT
```

---

### fun `borrowArt()`

```cadence
func borrowArt(id UInt64): &{Art.Public}?
```

---
