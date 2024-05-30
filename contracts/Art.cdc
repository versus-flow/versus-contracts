import "NonFungibleToken"
import "ViewResolver"
import "FungibleToken"
import "MetadataViews"
import "Content"

/// A NFT contract to store art
access(all)
contract Art: NonFungibleToken{ 


    access(all)
    let CollectionStoragePath: StoragePath

    access(all)
    let CollectionPublicPath: PublicPath

    access(all)
    var totalSupply: UInt64

    access(all)
    event ContractInitialized()

    access(all)
    event Created(id: UInt64, metadata: Metadata)

    access(all)
    event Editioned(id: UInt64, from: UInt64, edition: UInt64, maxEdition: UInt64)

    //The public interface can show metadata and the content for the Art piece
    access(all)
    resource interface Public{ 
        access(all)
        let id: UInt64

        access(all)
        let metadata: Metadata

        //these three are added because I think they will be in the standard. Atleast dieter thinks it will be needed
        access(all)
        let name: String

        access(all)
        let description: String

        access(all)
        let schema: String?

        access(all)
        fun content(): String?

        access(account)
        let royalty:{ String: Royalty}

        access(all)
        view fun cacheKey(): String

        access(all)
        view fun getMetadata(): Metadata

    }



    access(all)
    struct Metadata{ 
        access(all)
        let name: String

        access(all)
        let artist: String

        access(all)
        let artistAddress: Address

        access(all)
        let description: String

        access(all)
        let type: String

        access(all)
        let edition: UInt64

        access(all)
        let maxEdition: UInt64

        init(name: String, artist: String, artistAddress: Address, description: String, type: String, edition: UInt64, maxEdition: UInt64){ 
            self.name = name
            self.artist = artist
            self.artistAddress = artistAddress
            self.description = description
            self.type = type
            self.edition = edition
            self.maxEdition = maxEdition
        }
    }

    access(all)
    struct Royalty{ 
        access(all)
        let wallet: Capability<&{FungibleToken.Receiver}>

        access(all)
        let cut: UFix64

        /// @param wallet : The wallet to send royalty too
        init(wallet: Capability<&{FungibleToken.Receiver}>, cut: UFix64){ 
            self.wallet = wallet
            self.cut = cut
        }
    }

    access(all)
    resource NFT: NonFungibleToken.NFT, Public, ViewResolver.Resolver{ 
        //TODO: tighten up the permission here.
        access(all)
        let id: UInt64

        access(all)
        let name: String

        access(all)
        let description: String

        access(all)
        let schema: String?

        //content can either be embedded in the NFT as and URL or a pointer to a Content collection to be stored onChain
        //a pointer will be used for all editions of the same Art when it is editioned 
        access(all)
        let contentCapability: Capability<&Content.Collection>?

        access(all)
        let contentId: UInt64?

        access(all)
        let url: String?

        access(all)
        let metadata: Metadata

        access(account)
        let royalty:{ String: Royalty}

        init(initID: UInt64, metadata: Metadata, contentCapability: Capability<&Content.Collection>?, contentId: UInt64?, url: String?, royalty:{ String: Royalty}){ 
            self.id = initID
            self.metadata = metadata
            self.contentCapability = contentCapability
            self.contentId = contentId
            self.url = url
            self.royalty = royalty
            self.schema = nil
            self.name = metadata.name
            self.description = metadata.description
        }


        access(all)
        fun getRoyalty() : {String: Royalty} {
            return self.royalty
        }

        access(all) 
        view fun getMetadata(): Metadata{ 
            return self.metadata
        }

        access(all) 
        view fun cacheKey(): String{ 
            if self.url != nil{ 
                return self.url!
            }
            return (self.contentId!).toString()
        }

        //return the content for this NFT
        access(all)
        fun content(): String{ 
            if self.url != nil{ 
                return self.url!
            }
            let contentCollection = (self.contentCapability!).borrow()!
            return contentCollection.content(self.contentId!)
        }

        access(all)
        view fun getViews(): [Type]{ 
            var views: [Type] = [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.Display>(),
            Type<MetadataViews.Royalties>(),
            Type<MetadataViews.Edition>(),
            Type<MetadataViews.ExternalURL>()]
            return views
        }

        access(all)
        view fun resolveView(_ type: Type): AnyStruct?{ 
            if type == Type<MetadataViews.ExternalURL>(){ 
                return MetadataViews.ExternalURL("https://www.versus.auction/piece/".concat((self.owner!).address.toString()).concat("/").concat(self.id.toString()))
            }
            if type == Type<MetadataViews.NFTCollectionDisplay>(){ 
                return Art.resolveContractView(resourceType: Type<@NFT>(), viewType: type)
            }
            if type == Type<MetadataViews.NFTCollectionData>(){ 
                return Art.resolveContractView(resourceType: Type<@NFT>(), viewType:type)
            }
            if type == Type<MetadataViews.Royalties>(){ 
                var royalties: [MetadataViews.Royalty] = []
                for royaltyKey in self.royalty.keys{ 
                    let value = self.royalty[royaltyKey]!
                    royalties=royalties.concat([MetadataViews.Royalty(receiver: value.wallet, cut: value.cut, description: royaltyKey)])
                }
                return MetadataViews.Royalties(royalties)
            }
            if type == Type<MetadataViews.Display>(){ 
                return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_200/f_auto/maincache".concat(self.cacheKey())))
            }
            if type == Type<MetadataViews.Edition>(){ 
                return MetadataViews.Edition(name: nil, number: self.metadata.edition, max: self.metadata.maxEdition)
            }
            return nil
        }

        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
            return <-create Collection()
        }
    }

    //Standard NFT collectionPublic interface that can also borrowArt as the correct type
    access(all)
    resource interface CollectionPublic{ 
        access(all)
        fun deposit(token: @{NonFungibleToken.NFT})

        access(all)
        fun getIDs(): [UInt64]

        access(all)
        view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?

        access(all)
        fun borrowArt(id: UInt64): &{Art.Public}?
    }

    access(all)
    resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all)
        var ownedNFTs: @{UInt64:{NonFungibleToken.NFT}}

        init(){ 
            self.ownedNFTs <-{} 
        }

        // used after settlement to burn remaining art that was not sold
        access(account)
        fun burnAll(){ 
            for key in self.ownedNFTs.keys{ 
                log("burning art with key=".concat(key.toString()))
                destroy <-self.ownedNFTs.remove(key: key)
            }
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all)
        fun deposit(token: @{NonFungibleToken.NFT}){ 
            let token <- token as! @Art.NFT
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all)
        view fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        access(all)
        view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
            return &self.ownedNFTs[id]
        }

        // borrowArt returns a borrowed reference to a Art 
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        access(all)
        fun borrowArt(id: UInt64): &{Art.Public}? {  

            if self.ownedNFTs[id] != nil{ 
                let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
                return ref as! &Art.NFT
            } else{ 
                return nil
            }
        }

        access(all)
        view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
            pre{ 
                self.ownedNFTs[id] != nil:
                "NFT does not exist"
            }

            return &self.ownedNFTs[id]
        }

        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
            return <-create Collection()
        }


        access(all) view fun getIDsWithTypes(): {Type: [UInt64]} {
            return { Type<@NFT>() : self.ownedNFTs.keys}
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return { Type<@NFT>() : true}
        }

        access(all) view fun getLength() : Int {
            return self.ownedNFTs.length
        }

        access(all) view fun isSupportedNFTType(type: Type) : Bool {
            return type == Type<@NFT>()
        }


    }

    // public function that anyone can call to create a new empty collection
    access(all)
    fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
        return <-create Collection()
    }

    access(all)
    struct ArtData{ 
        access(all)
        let metadata: Art.Metadata

        access(all)
        let id: UInt64

        access(all)
        let cacheKey: String

        init(metadata: Art.Metadata, id: UInt64, cacheKey: String){ 
            self.metadata = metadata
            self.id = id
            self.cacheKey = cacheKey
        }
    }

    access(all)
    fun getContentForArt(address: Address, artId: UInt64): String?{ 
        let account = getAccount(address)
        if let artCollection = account.capabilities.borrow<&{Art.CollectionPublic}>(self.CollectionPublicPath) { 
            return (artCollection.borrowArt(id: artId)!).content()
        }
        return nil
    }

    // We cannot return the content here since it will be too big to run in a script
    access(all)
    fun getArt(address: Address): [ArtData]{ 
        var artData: [ArtData] = []
        let account = getAccount(address)
        if let artCollection = account.capabilities.borrow<&{Art.CollectionPublic}>(self.CollectionPublicPath){ 
            for id in artCollection.getIDs(){ 
                var art = artCollection.borrowArt(id: id)!
                artData.append(ArtData(metadata: art.getMetadata(), id: id, cacheKey: art.cacheKey()))
            }
        }
        return artData
    }

    //This method can only be called from another contract in the same account. In Versus case it is called from the VersusAdmin that is used to administer the solution
    access(account)
    fun createArtWithContent(name: String, artist: String, artistAddress: Address, description: String, url: String, type: String, royalty:{ String: Royalty}, edition: UInt64, maxEdition: UInt64): @Art.NFT{ 
        var newNFT <- create NFT(initID: Art.totalSupply, metadata: Metadata(name: name, artist: artist, artistAddress: artistAddress, description: description, type: type, edition: edition, maxEdition: maxEdition), contentCapability: nil, contentId: nil, url: url, royalty: royalty)
        emit Created(id: Art.totalSupply, metadata: newNFT.metadata)
        Art.totalSupply = Art.totalSupply + 1
        return <-newNFT
    }

    //This method can only be called from another contract in the same account. In Versus case it is called from the VersusAdmin that is used to administer the solution
    access(account)
    fun createArtWithPointer(name: String, artist: String, artistAddress: Address, description: String, type: String, contentCapability: Capability<&Content.Collection>, contentId: UInt64, royalty:{ String: Royalty}): @Art.NFT{ 
        let metadata = Metadata(name: name, artist: artist, artistAddress: artistAddress, description: description, type: type, edition: 1, maxEdition: 1)
        var newNFT <- create NFT(initID: Art.totalSupply, metadata: metadata, contentCapability: contentCapability, contentId: contentId, url: nil, royalty: royalty)
        emit Created(id: Art.totalSupply, metadata: newNFT.metadata)
        Art.totalSupply = Art.totalSupply + 1
        return <-newNFT
    }

    //This method can only be called from another contract in the same account. In Versus case it is called from the VersusAdmin that is used to administer the solution
    access(account)
    fun makeEdition(original: &NFT, edition: UInt64, maxEdition: UInt64): @Art.NFT{ 
        let metadata = Metadata(name: original.metadata.name, artist: original.metadata.artist, artistAddress: original.metadata.artistAddress, description: original.metadata.description, type: original.metadata.type, edition: edition, maxEdition: maxEdition)
        var newNFT <- create NFT(initID: Art.totalSupply, metadata: metadata, contentCapability: original.contentCapability, contentId: original.contentId, url: original.url, royalty: original.getRoyalty())
        emit Created(id: Art.totalSupply, metadata: newNFT.metadata)
        emit Editioned(id: Art.totalSupply, from: original.id, edition: edition, maxEdition: maxEdition)
        Art.totalSupply = Art.totalSupply + 1
        return <-newNFT
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    access(all) view fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
        case Type<MetadataViews.NFTCollectionData>():
            let collectionData= MetadataViews.NFTCollectionData(
                storagePath: Art.CollectionStoragePath, 
                publicPath: Art.CollectionPublicPath, 
                publicCollection: Type<&Art.Collection>(), 
                publicLinkedType: Type<&Art.Collection>(), 
                createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
                    return <-Art.createEmptyCollection(nftType: Type<@Collection>())
                }
            )
            return collectionData
        case Type<MetadataViews.NFTCollectionDisplay>():
            let externalURL = MetadataViews.ExternalURL("https://versus.auction")
            let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1295757455679528963/ibkAIRww_400x400.jpg"), mediaType: "image/jpeg")
            let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1295757455679528963/ibkAIRww_400x400.jpg"), mediaType: "image/jpeg")
            return MetadataViews.NFTCollectionDisplay(name: "Versus", description: "Curated auction house for fine art", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/FlowVersus")})

        }
        return nil
    }


    init(){ 
        // Initialize the total supply
        self.totalSupply = 0
        self.CollectionPublicPath = /public/versusArtCollection
        self.CollectionStoragePath = /storage/versusArtCollection
        self.account.storage.save<@{NonFungibleToken.Collection}>(<-Art.createEmptyCollection(nftType: Type<@Collection>()), to: Art.CollectionStoragePath)
        var _capForLinked1 = self.account.capabilities.storage.issue<&{Art.CollectionPublic}>(Art.CollectionStoragePath)
        self.account.capabilities.publish(_capForLinked1, at: Art.CollectionPublicPath)
        emit ContractInitialized()
    }
}
