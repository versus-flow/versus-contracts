# Resource Interface `Public`

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

## Functions

### fun `content()`

```cadence
func content(): String?
```

---

### fun `cacheKey()`

```cadence
func cacheKey(): String
```

---
