# Resource Interface `SalePublic`

```cadence
resource interface SalePublic {
}
```

## Functions

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

### fun `listSaleItems()`

```cadence
func listSaleItems(): [MarketplaceData]
```

---

### fun `getContent()`

```cadence
func getContent(tokenID UInt64): String
```

---
