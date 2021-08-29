# Contract `Marketplace`

```cadence
contract Marketplace {

    CollectionStoragePath:  StoragePath

    CollectionPublicPath:  PublicPath
}
```

## Interfaces
    
### resource interface `SalePublic`

```cadence
resource interface SalePublic {
}
```

[More...](Marketplace_SalePublic.md)

---
## Structs & Resources

### struct `MarketplaceData`

```cadence
struct MarketplaceData {

    id:  UInt64

    art:  Art.Metadata

    cacheKey:  String

    price:  UFix64
}
```

[More...](Marketplace_MarketplaceData.md)

---

### resource `SaleCollection`

```cadence
resource SaleCollection {

    forSale:  {UInt64: Art.NFT}

    prices:  {UInt64: UFix64}

    ownerVault:  Capability<&AnyResource{FungibleToken.Receiver}>
}
```

[More...](Marketplace_SaleCollection.md)

---
## Functions

### fun `createSaleCollection()`

```cadence
func createSaleCollection(ownerVault Capability<&{FungibleToken.Receiver}>): SaleCollection
```

---
## Events

### event `ForSale`

```cadence
event ForSale(id UInt64, price UFix64, from Address)
```

---

### event `SaleItem`

```cadence
event SaleItem(id UInt64, seller Address, price UFix64, active Bool, title String, artist String, edition UInt64, maxEdition UInt64, cacheKey String)
```

---

### event `PriceChanged`

```cadence
event PriceChanged(id UInt64, newPrice UFix64)
```

---

### event `TokenPurchased`

```cadence
event TokenPurchased(id UInt64, artId UInt64, price UFix64, from Address, to Address)
```

---

### event `RoyaltyPaid`

```cadence
event RoyaltyPaid(id UInt64, amount UFix64, to Address, name String)
```

---

### event `SaleWithdrawn`

```cadence
event SaleWithdrawn(id UInt64, from Address)
```

---
