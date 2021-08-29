# Contract `Art`

```cadence
contract Art {

    CollectionStoragePath:  StoragePath

    CollectionPublicPath:  PublicPath

    totalSupply:  UInt64
}
```

A NFT contract to store art

Implemented Interfaces:
  - `NonFungibleToken`

## Interfaces
    
### resource interface `Public`

```cadence
resource interface Public {

    id:  UInt64

    metadata:  Metadata

    name:  String

    description:  String

    schema:  String?

    royalty:  {String: Royalty}
}
```

[More...](Art_Public.md)

---
    
### resource interface `CollectionPublic`

```cadence
resource interface CollectionPublic {
}
```

[More...](Art_CollectionPublic.md)

---
## Structs & Resources

### struct `Metadata`

```cadence
struct Metadata {

    name:  String

    artist:  String

    artistAddress:  Address

    description:  String

    type:  String

    edition:  UInt64

    maxEdition:  UInt64
}
```

[More...](Art_Metadata.md)

---

### struct `Royalty`

```cadence
struct Royalty {

    wallet:  Capability<&{FungibleToken.Receiver}>

    cut:  UFix64
}
```

[More...](Art_Royalty.md)

---

### resource `NFT`

```cadence
resource NFT {

    id:  UInt64

    name:  String

    description:  String

    schema:  String?

    contentCapability:  Capability<&Content.Collection>?

    contentId:  UInt64?

    url:  String?

    metadata:  Metadata

    royalty:  {String: Royalty}
}
```

[More...](Art_NFT.md)

---

### resource `Collection`

```cadence
resource Collection {

    ownedNFTs:  {UInt64: NonFungibleToken.NFT}
}
```

[More...](Art_Collection.md)

---

### struct `ArtData`

```cadence
struct ArtData {

    metadata:  Art.Metadata

    id:  UInt64

    cacheKey:  String
}
```

[More...](Art_ArtData.md)

---
## Functions

### fun `createEmptyCollection()`

```cadence
func createEmptyCollection(): NonFungibleToken.Collection
```

---

### fun `getContentForArt()`

```cadence
func getContentForArt(address Address, artId UInt64): String?
```

---

### fun `getArt()`

```cadence
func getArt(address Address): [ArtData]
```

---

### fun `createArtWithContent()`

```cadence
func createArtWithContent(name String, artist String, artistAddress Address, description String, url String, type String, royalty {String: Royalty}): Art.NFT
```

---

### fun `createArtWithPointer()`

```cadence
func createArtWithPointer(name String, artist String, artistAddress Address, description String, type String, contentCapability Capability<&Content.Collection>, contentId UInt64, royalty {String: Royalty}): Art.NFT
```

---

### fun `makeEdition()`

```cadence
func makeEdition(original &NFT, edition UInt64, maxEdition UInt64): Art.NFT
```

---
## Events

### event `ContractInitialized`

```cadence
event ContractInitialized()
```

---

### event `Withdraw`

```cadence
event Withdraw(id UInt64, from Address?)
```

---

### event `Deposit`

```cadence
event Deposit(id UInt64, to Address?)
```

---

### event `Created`

```cadence
event Created(id UInt64, metadata Metadata)
```

---

### event `Editioned`

```cadence
event Editioned(id UInt64, from UInt64, edition UInt64, maxEdition UInt64)
```

---
