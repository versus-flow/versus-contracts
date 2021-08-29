# Contract `Content`

```cadence
contract Content {

    totalSupply:  UInt64

    CollectionStoragePath:  StoragePath

    CollectionPrivatePath:  PrivatePath
}
```

## Interfaces
    
### resource interface `PublicContent`

```cadence
resource interface PublicContent {
}
```

[More...](Content_PublicContent.md)

---
## Structs & Resources

### resource `Blob`

```cadence
resource Blob {

    id:  UInt64

    content:  String
}
```

[More...](Content_Blob.md)

---

### resource `Collection`

```cadence
resource Collection {

    contents:  {UInt64: Blob}
}
```

[More...](Content_Collection.md)

---
## Functions

### fun `createEmptyCollection()`

```cadence
func createEmptyCollection(): Content.Collection
```

---

### fun `createContent()`

```cadence
func createContent(_ String): Content.Blob
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
event Created(id UInt64)
```

---
