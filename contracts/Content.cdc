access(all)
contract Content{ 
    access(all)
    var totalSupply: UInt64

    access(all)
    let CollectionStoragePath: StoragePath

    access(all)
    let CollectionPrivatePath: PrivatePath

    access(all)
    event ContractInitialized()

    access(all)
    event Withdraw(id: UInt64, from: Address?)

    access(all)
    event Deposit(id: UInt64, to: Address?)

    access(all)
    event Created(id: UInt64)

    access(all)
    resource Blob{ 
        access(all)
        let id: UInt64

        access(contract)
        var content: String

        init(initID: UInt64, content: String){ 
            self.id = initID
            self.content = content
        }
    }

    //return the content for this NFT
    access(all)
    resource interface PublicContent{ 
        access(all)
        fun content(_ id: UInt64): String?
    }

    access(all)
    resource Collection: PublicContent{ 
        access(all)
        var contents: @{UInt64: Blob}

        init(){ 
            self.contents <-{} 
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        access(all)
        fun withdraw(withdrawID: UInt64): @Blob{ 
            let token <- self.contents.remove(key: withdrawID) ?? panic("missing content")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all)
        fun deposit(token: @Blob){ 
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.contents[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all)
        fun getIDs(): [UInt64]{ 
            return self.contents.keys
        }

        access(all)
        fun content(_ id: UInt64): String{ 
            return self.contents[id]?.content ?? panic("Content blob does not exist")
        }
    }

    access(account)
    fun createEmptyCollection(): @Content.Collection{ 
        return <-create Collection()
    }

    access(account)
    fun createContent(_ content: String): @Content.Blob{ 
        var newNFT <- create Blob(initID: Content.totalSupply, content: content)
        emit Created(id: Content.totalSupply)
        Content.totalSupply = Content.totalSupply + UInt64(1)
        return <-newNFT
    }

    init(){ 
        // Initialize the total supply
        self.totalSupply = 0
        self.CollectionPrivatePath = /private/versusContentCollection
        self.CollectionStoragePath = /storage/versusContentCollection
        let account = self.account
        account.storage.save(<-Content.createEmptyCollection(), to: Content.CollectionStoragePath)
        emit ContractInitialized()
    }
}
