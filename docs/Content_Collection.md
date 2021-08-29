# Resource `Collection`

```cadence
resource Collection {

    contents:  {UInt64: Blob}
}
```


Implemented Interfaces:
  - `PublicContent`


### Initializer

```cadence
func init()
```


## Functions

### fun `withdraw()`

```cadence
func withdraw(withdrawID UInt64): Blob
```

---

### fun `deposit()`

```cadence
func deposit(token Blob)
```

---

### fun `getIDs()`

```cadence
func getIDs(): [UInt64]
```

---

### fun `content()`

```cadence
func content(_ UInt64): String
```

---
