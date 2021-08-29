# Resource `Admin`

```cadence
resource Admin {

    server:  Capability<&Versus.DropCollection>?
}
```


Implemented Interfaces:
  - `AdminPublic`


### Initializer

```cadence
func init()
```


## Functions

### fun `addCapability()`

```cadence
func addCapability(_ Capability<&Versus.DropCollection>)
```

---

### fun `settle()`

```cadence
func settle(_ UInt64)
```

---

### fun `setVersusCut()`

```cadence
func setVersusCut(_ UFix64)
```

---

### fun `createDrop()`

```cadence
func createDrop(nft NonFungibleToken.NFT, editions UInt64, minimumBidIncrement UFix64, minimumBidUniqueIncrement UFix64, startTime UFix64, startPrice UFix64, vaultCap Capability<&{FungibleToken.Receiver}>, duration UFix64, extensionOnLateBid UFix64)
```

---

### fun `mintArt()`

```cadence
func mintArt(artist Address, artistName String, artName String, content String, description String): Art.NFT
```

---

### fun `editionArt()`

```cadence
func editionArt(art &Art.NFT, edition UInt64, maxEdition UInt64): Art.NFT
```

---

### fun `editionAndDepositArt()`

```cadence
func editionAndDepositArt(art &Art.NFT, to [Address])
```

---

### fun `getContent()`

```cadence
func getContent(): &Content.Collection
```

---

### fun `getFlowWallet()`

```cadence
func getFlowWallet(): &FungibleToken.Vault
```

---

### fun `getArtCollection()`

```cadence
func getArtCollection(): &NonFungibleToken.Collection
```

---

### fun `getDropCollection()`

```cadence
func getDropCollection(): &Versus.DropCollection
```

---

### fun `getVersusProfile()`

```cadence
func getVersusProfile(): &Profile.User
```

---
