# Resource `NFT`

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


Implemented Interfaces:
  - `NonFungibleToken.INFT`
  - `Public`


### Initializer

```cadence
func init(initID UInt64, metadata Metadata, contentCapability Capability<&Content.Collection>?, contentId UInt64?, url String?, royalty {String: Royalty})
```


## Functions

### fun `cacheKey()`

```cadence
func cacheKey(): String
```

---

### fun `content()`

```cadence
func content(): String
```

---
