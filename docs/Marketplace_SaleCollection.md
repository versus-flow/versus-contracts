# Resource `SaleCollection`

```cadence
resource SaleCollection {

    forSale:  {UInt64: Art.NFT}

    prices:  {UInt64: UFix64}

    ownerVault:  Capability<&AnyResource{FungibleToken.Receiver}>
}
```


Implemented Interfaces:
  - `SalePublic`


### Initializer

```cadence
func init(vault Capability<&AnyResource{FungibleToken.Receiver}>)
```


## Functions

### fun `getContent()`

```cadence
func getContent(tokenID UInt64): String
```

---

### fun `listSaleItems()`

```cadence
func listSaleItems(): [MarketplaceData]
```

---

### fun `borrowArt()`

```cadence
func borrowArt(id UInt64): &{Art.Public}?
```

---

### fun `withdraw()`

```cadence
func withdraw(tokenID UInt64): Art.NFT
```

---

### fun `listForSale()`

```cadence
func listForSale(token Art.NFT, price UFix64)
```

---

### fun `changePrice()`

```cadence
func changePrice(tokenID UInt64, newPrice UFix64)
```

---

### fun `purchase()`

```cadence
func purchase(tokenID UInt64, recipientCap Capability<&{Art.CollectionPublic}>, buyTokens FungibleToken.Vault)
```

---

### fun `getSaleItem()`

```cadence
func getSaleItem(tokenID UInt64): MarketplaceData
```

---

### fun `getIDs()`

```cadence
func getIDs(): [UInt64]
```

---
