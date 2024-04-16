
import "FungibleToken"
import "FlowToken"
import "Art"
import "NonFungibleToken"
import "Content"
import "Auction"
import "Profile"

/*
The main contract in the Versus auction system.

A versions auction contains a single auction and a group of auctions and either of them will be fulfilled while the other will be cancelled
Currently this is modeled as 1 vs x, but It could easily be modeled as x vs y  so you could have 5 editions vs 10 editions if you want to

The auctions themselves are not implemented in this contract but rather in the Auction contract. The goal here is to be able to
reuse the Auction contract for other things if somebody would want that.

*/

access(all)
contract Versus{ 

    //A set of capability and storage paths used in this contract
    access(all)
    let VersusAdminPublicPath: PublicPath

    access(all)
    let VersusAdminStoragePath: StoragePath

    access(all)
    let CollectionStoragePath: StoragePath

    access(all)
    let CollectionPublicPath: PublicPath

    //counter for drops that is incremented every time there is a new versus drop made
    access(all)
    var totalDrops: UInt64

    //emitted when a drop is extended
    access(all)
    event DropExtended(
        name: String,
        artist: String,
        dropId: UInt64,
        extendWith: Fix64,
        extendTo: Fix64
    )

    access(all)
    event Bid(
        name: String,
        artist: String,
        edition: String,
        bidder: Address,
        price: UFix64,
        dropId: UInt64,
        auctionId: UInt64
    )

    //emitted when a bid is made
    access(all)
    event ExtendedBid(
        name: String,
        artist: String,
        edition: String,
        bidderAddress: Address,
        bidderName: String,
        price: UFix64,
        oldBidderAddress: Address?,
        oldBidderName: String,
        oldPrice: UFix64?,
        dropId: UInt64,
        auctionId: UInt64,
        auctionEndAt: Fix64,
        extendWith: Fix64,
        cacheKey: String,
        oldLeader: String,
        newLeader: String
    )

    //emitted when a drop is created
    access(all)
    event DropCreated(
        name: String,
        artist: String,
        editions: UInt64,
        owner: Address,
        dropId: UInt64
    )

    access(all)
    event DropDestroyed(dropId: UInt64)

    //emitted when a drop is settled, that is it ends and either the uniqe or the edition side wins
    access(all)
    event Settle(name: String, artist: String, winner: String, price: UFix64, dropId: UInt64)

    //emitted when the winning side in the auction changes
    access(all)
    event LeaderChanged(name: String, artist: String, winning: String, dropId: UInt64)

    //A Drop in versus represents a single auction vs an editioned auction
    access(all)
    resource Drop{ 
        access(contract)
        let uniqueAuction: @Auction.AuctionItem

        access(contract)
        let editionAuctions: @Auction.AuctionCollection

        access(contract)
        let dropID: UInt64

        //this is used to be able to query events for a drop from a given start point
        access(contract)
        var firstBidBlock: UInt64?

        access(contract)
        var settledAt: UInt64?

        access(contract)
        var extensionOnLateBid: UFix64

        //Store metadata here would allow us to show this after the drop has ended. The NFTS are gone then but the  metadta remains here
        access(contract)
        let metadata: Art.Metadata

        //these two together are a pointer to the content in the Drop. Storing them here means we can show the art after the drop has ended
        access(contract)
        var contentId: UInt64

        access(contract)
        var contentCapability: Capability<&Content.Collection>

        init(
            uniqueAuction: @Auction.AuctionItem,
            editionAuctions: @Auction.AuctionCollection,
            extensionOnLateBid: UFix64,
            contentId: UInt64,
            contentCapability: Capability<&Content.Collection>
        ){ 
            Versus.totalDrops = Versus.totalDrops + 1 
            self.dropID = Versus.totalDrops
            self.uniqueAuction <- uniqueAuction
            self.editionAuctions <- editionAuctions
            self.firstBidBlock = nil
            self.settledAt = nil
            self.metadata = self.uniqueAuction.getAuctionStatus().metadata!
            self.extensionOnLateBid = extensionOnLateBid
            self.contentId = contentId
            self.contentCapability = contentCapability
        }

        access(all)
        fun getContent(): String{ 
            let contentCollection = self.contentCapability.borrow()!
            return contentCollection.content(self.contentId)
        }

        //Returns a DropStatus struct that could be used in a script to show information about the drop
        access(all)
        fun getDropStatus(): DropStatus{ 
            let uniqueRef = &self.uniqueAuction as &Auction.AuctionItem
            let editionRef = &self.editionAuctions as &Auction.AuctionCollection
            let editionStatuses = editionRef.getAuctionStatuses()
            var editionPrice: UFix64 = 0.0
            let editionDropAcutionStatus:{ UInt64: DropAuctionStatus} ={} 
            for es in editionStatuses.keys{ 
                var status = editionStatuses[es]!
                editionDropAcutionStatus[es] = DropAuctionStatus(status)
                editionPrice = editionPrice + status.price
            }
            let uniqueStatus = uniqueRef.getAuctionStatus()
            var winningStatus = ""
            var difference = 0.0
            if editionPrice > uniqueStatus.price{ 
                winningStatus = "EDITIONED"
                difference = editionPrice - uniqueStatus.price
            } else if editionPrice == uniqueStatus.price{ 
                winningStatus = "TIE"
                difference = 0.0
            } else{ 
                difference = uniqueStatus.price - editionPrice
                winningStatus = "UNIQUE"
            }
            let block = getCurrentBlock()
            let time = Fix64(block.timestamp)
            var started = uniqueStatus.startTime < time
            var active = true
            if !started{ 
                active = false
            } else if uniqueStatus.completed{ 
                active = false
            } else if uniqueStatus.expired && winningStatus != "TIE"{ 
                active = false
            }
            return DropStatus(
                dropId: self.dropID,
                uniqueStatus: uniqueStatus,
                editionsStatuses: editionDropAcutionStatus,
                editionPrice: editionPrice,
                status: winningStatus,
                firstBidBlock: self.firstBidBlock,
                difference: difference,
                metadata: self.metadata,
                settledAt: self.settledAt,
                active: active,
                startPrice: uniqueRef.startPrice
            )
        }

        access(all)
        fun calculateStatus(edition: UFix64, unique: UFix64): String{ 
            var winningStatus = ""
            if edition > unique{ 
                winningStatus = "EDITIONED"
            } else if edition == unique{ 
                winningStatus = "TIE"
            } else{ 
                winningStatus = "UNIQUE"
            }
            return winningStatus
        }

        access(all)
        fun settle(cutPercentage: UFix64, vault: Capability<&{FungibleToken.Receiver}>){ 
            let status = self.getDropStatus()
            if status.settledAt != nil{ 
                panic("Drop has already been settled")
            }
            if status.expired == false{ 
                panic("Auction has not completed yet")
            }
            let winning = status.winning
            var price = 0.0
            if winning == "UNIQUE"{ 
                self.uniqueAuction.settleAuction(cutPercentage: cutPercentage, cutVault: vault)
                self.cancelAllEditionedAuctions()
                price = status.uniquePrice
            } else if winning == "EDITIONED"{ 
                self.uniqueAuction.returnAuctionItemToOwner()
                self.settleAllEditionedAuctions()
                price = status.editionPrice
            } else{ 
                panic("tie")
            }
            self.settledAt = getCurrentBlock().height
            emit Settle(
                name: status.metadata.name,
                artist: status.metadata.artist,
                winner: winning,
                price: price,
                dropId: self.dropID
            )
        }

        access(all)
        fun settleAllEditionedAuctions(){ 
            for id in self.editionAuctions.keys(){ 
                self.editionAuctions.settleAuction(id)
            }
        }

        access(all)
        fun cancelAllEditionedAuctions(){ 
            for id in self.editionAuctions.keys(){ 
                self.editionAuctions.cancelAuction(id)
            }
        }

        access(self)
        fun getAuction(auctionId: UInt64): &Auction.AuctionItem{ 
            let dropStatus = self.getDropStatus()
            if self.uniqueAuction.auctionID == auctionId{ 
                return &self.uniqueAuction 
            } else{ 
                let editionStatus = dropStatus.editionsStatuses[auctionId]!
                return (&self.editionAuctions.auctionItems[auctionId])!
            }
        }

        access(all)
        fun currentBidForUser(auctionId: UInt64, address: Address): UFix64{ 
            let auction = self.getAuction(auctionId: auctionId)
            return auction.currentBidForUser(address: address)
        }

        //place a bid on a given auction
        access(all)
        fun placeBid(
            auctionId: UInt64,
            bidTokens: @{FungibleToken.Vault},
            vaultCap: Capability<&{FungibleToken.Receiver}>,
            collectionCap: Capability<&{Art.CollectionPublic}>
        ){ 
            pre{ 
                collectionCap.check() == true:
                "Collection capability must be linked"
                vaultCap.check() == true:
                "Vault capability must be linked"
            }
            let dropStatus = self.getDropStatus()
            var editionPrice = dropStatus.editionPrice
            var uniquePrice = dropStatus.uniquePrice
            let block = getCurrentBlock()
            let time = Fix64(block.timestamp)
            if dropStatus.startTime > time{ 
                panic("The drop has not started")
            }
            if dropStatus.endTime < time && dropStatus.winning != "TIE"{ 
                panic("This drop has ended")
            }
            let bidEndTime = time + Fix64(self.extensionOnLateBid)

            //we save the time of the first bid so that it can be used to fetch events from that given block
            if self.firstBidBlock == nil{ 
                self.firstBidBlock = block.height
            }
            var endTime = dropStatus.endTime
            var extendWith = 0.0 as Fix64

            //We need to extend the auction since there is too little time left. If we did not do this a late user could potentially win with a cheecky bid
            if dropStatus.endTime < bidEndTime{ 
                extendWith = bidEndTime - dropStatus.endTime
                endTime = bidEndTime
                emit DropExtended(name: dropStatus.metadata.name, artist: dropStatus.metadata.artist, dropId: self.dropID, extendWith: extendWith, extendTo: bidEndTime)
                self.extendDropWith(UFix64(extendWith))
            }
            let bidder = vaultCap.address
            let currentBidForUser = self.currentBidForUser(auctionId: auctionId, address: bidder)
            let bidPrice = bidTokens.balance + currentBidForUser
            var edition: String = "1 of 1"
            var oldBidder: Address? = nil
            var oldPrice: UFix64? = nil
            //the bid is on a unique auction so we place the bid there
            if self.uniqueAuction.auctionID == auctionId{ 
                let auctionRef = &self.uniqueAuction as &Auction.AuctionItem
                oldBidder = dropStatus.uniqueStatus.leader
                oldPrice = dropStatus.uniquePrice
                uniquePrice = bidPrice
                auctionRef.placeBid(bidTokens: <-bidTokens, vaultCap: vaultCap, collectionCap: collectionCap)
            } else{ 
                editionPrice = editionPrice + bidTokens.balance
                let editionStatus = dropStatus.editionsStatuses[auctionId]!
                oldBidder = editionStatus.leader
                oldPrice = editionStatus.price
                edition = editionStatus.edition.toString().concat(" of ").concat(editionStatus.maxEdition.toString())
                let editionsRef = &self.editionAuctions as &Auction.AuctionCollection
                editionsRef.placeBid(id: auctionId, bidTokens: <-bidTokens, vaultCap: vaultCap, collectionCap: collectionCap)
            }
            emit Bid(
                name: dropStatus.metadata.name,
                artist: dropStatus.metadata.artist,
                edition: edition,
                bidder: bidder,
                price: bidPrice,
                dropId: self.dropID,
                auctionId: auctionId
            )
            let newStatus = self.calculateStatus(edition: editionPrice, unique: uniquePrice)
            if dropStatus.winning != newStatus{ 
                emit LeaderChanged(name: dropStatus.metadata.name, artist: dropStatus.metadata.artist, winning: newStatus, dropId: self.dropID)
            }
            var bidderName = ""
            let bidderProfileCap =
            getAccount(bidder).capabilities.get<&{Profile.Public}>(Profile.publicPath)!
            if bidderProfileCap.check(){ 
                bidderName = (bidderProfileCap.borrow()!).getName()
            }
            var oldBidderName = ""
            if oldBidder != nil{ 
                if oldBidder == bidder{ 
                    oldBidderName = bidderName
                } else{ 
                    let oldBidderProfileCap = getAccount(oldBidder!).capabilities.get<&{Profile.Public}>(Profile.publicPath)!
                    if oldBidderProfileCap.check(){ 
                        oldBidderName = (oldBidderProfileCap.borrow()!).getName()
                    }
                }
            }
            emit ExtendedBid(
                name: dropStatus.metadata.name,
                artist: dropStatus.metadata.artist,
                edition: edition,
                bidderAddress: bidder,
                bidderName: bidderName,
                price: bidPrice,
                oldBidderAddress: oldBidder,
                oldBidderName: oldBidderName,
                oldPrice: oldPrice,
                dropId: self.dropID,
                auctionId: auctionId,
                auctionEndAt: endTime,
                extendWith: extendWith,
                cacheKey: self.contentId.toString(),
                oldLeader: dropStatus.winning,
                newLeader: newStatus
            )
        }

        //This would make it possible to extend the drop with more time from an admin interface
        //here we just delegate to the auctions and extend them all
        access(all)
        fun extendDropWith(_ time: UFix64){ 
            log("Drop extended with duration")
            self.uniqueAuction.extendWith(time)
            self.editionAuctions.extendAllAuctionsWith(time)
        }
    }

    //this is a simpler version of the Acution status since we do not need to duplicate all the fields
    //edition and maxEidtion will not be kept here after the auction has been settled.
    //Really not sure on how to handle showing historic drops so for now I will just leave it as it is
    access(all)
    struct DropAuctionStatus{ 
        access(all)
        let id: UInt64

        access(all)
        let price: UFix64

        access(all)
        let bidIncrement: UFix64

        access(all)
        let bids: UInt64

        access(all)
        let edition: UInt64

        access(all)
        let maxEdition: UInt64

        access(all)
        let leader: Address?

        access(all)
        let minNextBid: UFix64

        init(_ auctionStatus: Auction.AuctionStatus){ 
            self.price = auctionStatus.price
            self.bidIncrement = auctionStatus.bidIncrement
            self.bids = auctionStatus.bids
            self.edition = auctionStatus.metadata?.edition ?? 0
            self.maxEdition = auctionStatus.metadata?.maxEdition ?? 0 
            self.leader = auctionStatus.leader
            self.minNextBid = auctionStatus.minNextBid
            self.id = auctionStatus.id
        }
    }

    //The struct that holds status information of a drop.
    //this probably has some duplicated data that could go away. like do you need both a settled and settledAt? and active?
    access(all)
    struct DropStatus{ 
        access(all)
        let dropId: UInt64

        access(all)
        let uniquePrice: UFix64

        access(all)
        let editionPrice: UFix64

        access(all)
        let difference: UFix64

        access(all)
        let endTime: Fix64

        access(all)
        let startTime: Fix64

        access(all)
        let uniqueStatus: DropAuctionStatus

        access(all)
        let editionsStatuses:{ UInt64: DropAuctionStatus}

        access(all)
        let winning: String

        access(all)
        let active: Bool

        access(all)
        let timeRemaining: Fix64

        access(all)
        let firstBidBlock: UInt64?

        access(all)
        let metadata: Art.Metadata

        access(all)
        let expired: Bool

        access(all)
        let settledAt: UInt64?

        access(all)
        let startPrice: UFix64

        init(
            dropId: UInt64,
            uniqueStatus: Auction.AuctionStatus,
            editionsStatuses:{ 
                UInt64: DropAuctionStatus
            },
            editionPrice: UFix64,
            status: String,
            firstBidBlock: UInt64?,
            difference: UFix64,
            metadata: Art.Metadata,
            settledAt: UInt64?,
            active: Bool,
            startPrice: UFix64
        ){ 
            self.dropId = dropId
            self.uniqueStatus = DropAuctionStatus(uniqueStatus)
            self.editionsStatuses = editionsStatuses
            self.uniquePrice = uniqueStatus.price
            self.editionPrice = editionPrice
            self.endTime = uniqueStatus.endTime
            self.startTime = uniqueStatus.startTime
            self.timeRemaining = uniqueStatus.timeRemaining
            self.active = active
            self.winning = status
            self.firstBidBlock = firstBidBlock
            self.difference = difference
            self.metadata = metadata
            self.expired = uniqueStatus.expired
            self.settledAt = settledAt
            self.startPrice = startPrice
        }
    }

    //An resource interface that everybody can access through a public capability.
    access(all)
    resource interface PublicDrop{ 
        access(all)
        fun currentBidForUser(dropId: UInt64, auctionId: UInt64, address: Address): UFix64

        access(all)
        fun getAllStatuses():{ UInt64: DropStatus}

        access(all)
        fun getCacheKeyForDrop(_ dropId: UInt64): UInt64

        access(all)
        fun getStatus(dropId: UInt64): DropStatus

        access(all)
        fun getArt(dropId: UInt64): String

        access(all)
        fun placeBid(
            dropId: UInt64,
            auctionId: UInt64,
            bidTokens: @{FungibleToken.Vault},
            vaultCap: Capability<&{FungibleToken.Receiver}>,
            collectionCap: Capability<&{Art.CollectionPublic}>
        )
    }

    access(all)
    resource interface AdminDrop{ 
        access(all)
        fun createDrop(
            nft: @{NonFungibleToken.NFT},
            editions: UInt64,
            minimumBidIncrement: UFix64,
            minimumBidUniqueIncrement: UFix64,
            startTime: UFix64,
            startPrice: UFix64,
            vaultCap: Capability<&{FungibleToken.Receiver}>,
            duration: UFix64,
            extensionOnLateBid: UFix64
        )

        access(all)
        fun settle(_ dropId: UInt64)
    }

    access(all)
    resource DropCollection: PublicDrop, AdminDrop{ 
        access(account)
        var drops: @{UInt64: Drop}

        //it is possible to adjust the cutPercentage if you own a Versus.DropCollection
        access(account)
        var cutPercentage: UFix64

        access(account)
        let marketplaceVault: Capability<&{FungibleToken.Receiver}>

        //NFTs that are not sold are put here when a bid is settled.
        access(account)
        let marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>

        init(marketplaceVault: Capability<&{FungibleToken.Receiver}>, marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>, cutPercentage: UFix64){ 
            self.marketplaceNFTTrash = marketplaceNFTTrash
            self.cutPercentage = cutPercentage
            self.marketplaceVault = marketplaceVault
            self.drops <-{} 
        }

        access(all)
        fun withdraw(_ withdrawID: UInt64): @Drop{ 
            let token <- self.drops.remove(key: withdrawID) ?? panic("missing drop")
            return <-token
        }

        /// Set the cut percentage for versus
        /// @param cut: The cut percentage as a Ufix64 that versus will take for each drop
        access(all)
        fun setCutPercentage(_ cut: UFix64){ 
            self.cutPercentage = cut
        }

        // When creating a drop you send in an NFT and the number of editions you want to sell vs the unique one
        // There will then be minted edition number of extra copies and put into the editions auction
        access(all)
        fun createDrop(nft: @{NonFungibleToken.NFT}, editions: UInt64, minimumBidIncrement: UFix64, minimumBidUniqueIncrement: UFix64, startTime: UFix64, startPrice: UFix64, vaultCap: Capability<&{FungibleToken.Receiver}>, duration: UFix64, extensionOnLateBid: UFix64){ 
            pre{ 
                vaultCap.check() == true:
                "Vault capability should exist"
            }
            let art <- nft as! @Art.NFT
            let contentCapability = art.contentCapability!
            let contentId = art.contentId!
            let metadata = art.metadata
            //Sending in a NFTEditioner capability here and using that instead of this loop would probably make sense.
            let editionedAuctions <- Auction.createAuctionCollection(marketplaceVault: self.marketplaceVault, cutPercentage: self.cutPercentage)
            var currentEdition = 1 as UInt64
            while currentEdition <= editions{ 
                editionedAuctions.createAuction(token: <-Art.makeEdition(original: &art as &Art.NFT, edition: currentEdition, maxEdition: editions), minimumBidIncrement: minimumBidIncrement, auctionLength: duration, auctionStartTime: startTime, startPrice: startPrice, collectionCap: self.marketplaceNFTTrash, vaultCap: vaultCap)
                currentEdition = currentEdition + 1 
            }

            //copy the metadata of the previous art since that is used to mint the copies
            let item <- Auction.createStandaloneAuction(token: <-art, minimumBidIncrement: minimumBidUniqueIncrement, auctionLength: duration, auctionStartTime: startTime, startPrice: startPrice, collectionCap: self.marketplaceNFTTrash, vaultCap: vaultCap)
            let drop <- create Drop(uniqueAuction: <-item, editionAuctions: <-editionedAuctions, extensionOnLateBid: extensionOnLateBid, contentId: contentId, contentCapability: contentCapability)
            emit DropCreated(name: metadata.name, artist: metadata.artist, editions: editions, owner: vaultCap.address, dropId: drop.dropID)
            let oldDrop <- self.drops[drop.dropID] <- drop
            destroy oldDrop
        }

        //Get all the drop statuses
        access(all)
        fun getAllStatuses():{ UInt64: DropStatus}{ 
            var dropStatus:{ UInt64: DropStatus} ={} 
            for id in self.drops.keys{ 
                let itemRef = (&self.drops[id] as &Drop?)!
                dropStatus[id] = itemRef.getDropStatus()
            }
            return dropStatus
        }

        access(contract)
        fun getDrop(_ dropId: UInt64): &Drop{ 
            pre{ 
                self.drops[dropId] != nil:
                "drop doesn't exist"
            }
            return (&self.drops[dropId])!
        }

        access(all)
        fun getDropByCacheKey(_ cacheKey: UInt64): DropStatus?{ 
            var dropStatus:{ UInt64: DropStatus} ={} 
            for id in self.drops.keys{ 
                let itemRef = (&self.drops[id] as &Drop?)!
                if itemRef.contentId == cacheKey{ 
                    return itemRef.getDropStatus()
                }
            }
            return nil
        }

        access(all)
        fun getCacheKeyForDrop(_ dropId: UInt64): UInt64{ 
            return self.getDrop(dropId).contentId
        }

        access(all)
        fun getStatus(dropId: UInt64): DropStatus{ 
            return self.getDrop(dropId).getDropStatus()
        }

        //get the art for this drop
        access(all)
        fun getArt(dropId: UInt64): String{ 
            return self.getDrop(dropId).getContent()
        }

        access(all)
        fun getArtType(dropId: UInt64): String{ 
            return self.getDrop(dropId).metadata.type
        }

        //settle a drop
        access(all)
        fun settle(_ dropId: UInt64){ 
            self.getDrop(dropId).settle(cutPercentage: self.cutPercentage, vault: self.marketplaceVault)
        }

        access(all)
        fun currentBidForUser(dropId: UInt64, auctionId: UInt64, address: Address): UFix64{ 
            return self.getDrop(dropId).currentBidForUser(auctionId: auctionId, address: address)
        }

        //place a bid, will just delegate to the method in the drop collection
        access(all)
        fun placeBid(dropId: UInt64, auctionId: UInt64, bidTokens: @{FungibleToken.Vault}, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{Art.CollectionPublic}>){ 
            self.getDrop(dropId).placeBid(auctionId: auctionId, bidTokens: <-bidTokens, vaultCap: vaultCap, collectionCap: collectionCap)
        }
    }

    // Get the art stored on chain for this drop
    access(all)
    fun getArtForDrop(_ dropId: UInt64): String?{ 
        let versusCap =
        Versus.account.capabilities.get<&{Versus.PublicDrop}>(self.CollectionPublicPath)!
        if let versus = versusCap.borrow(){ 
            return versus.getArt(dropId: dropId)
        }
        return nil
    }

    /*
    Get an active drop in the versus marketplace

    */

    access(all)
    fun getDrops(): [Versus.DropStatus]{ 
        let account = Versus.account
        let versusCap = account.capabilities.get<&{Versus.PublicDrop}>(self.CollectionPublicPath)!
        return (versusCap.borrow()!).getAllStatuses().values
    }

    access(all)
    fun getDrop(_ id: UInt64): Versus.DropStatus?{ 
        let account = Versus.account
        let versusCap = account.capabilities.get<&{Versus.PublicDrop}>(Versus.CollectionPublicPath)!
        if let versus = versusCap.borrow(){ 
            return versus.getStatus(dropId: id)
        }
        return nil
    }

    /*
    Get the first active drop in the versus marketplace
    */

    access(all)
    fun getActiveDrop(): Versus.DropStatus?{ 
        // get the accounts' public address objects
        let account = Versus.account
        let versusCap = account.capabilities.get<&{Versus.PublicDrop}>(self.CollectionPublicPath)!
        if let versus = versusCap.borrow(){ 
            let versusStatuses = versus.getAllStatuses()
            for s in versusStatuses.keys{ 
                let status = versusStatuses[s]!
                if status.active != false{ 
                    return status
                }
            }
        }
        return nil
    }

    //The interface used to add a Versus Drop Collection capability to a AdminPublic
    access(all)
    resource interface AdminPublic{ 
        access(all)
        fun addCapability(_ cap: Capability<&Versus.DropCollection>)
    }

    //The versus admin resource that a client will create and store, then link up a public AdminPublic
    access(all)
    resource Admin: AdminPublic{ 
        access(self)
        var server: Capability<&Versus.DropCollection>?

        init(){ 
            self.server = nil
        }

        access(all)
        fun addCapability(_ cap: Capability<&Versus.DropCollection>){ 
            pre{ 
                cap.check():
                "Invalid server capablity"
                self.server == nil:
                "Server already set"
            }
            self.server = cap
        }

        // This will settle/end an auction
        access(all)
        fun settle(_ dropId: UInt64){ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            ((self.server!).borrow()!).settle(dropId)

            //since settling will return all items not sold to the NFTTrash, we take out the trash here.
            let artC = Versus.account.storage.borrow<&Art.Collection>(from: Art.CollectionStoragePath)!
            artC.burnAll()
        }

        access(all)
        fun setVersusCut(_ num: UFix64){ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            let dc: &Versus.DropCollection = (self.server!).borrow()!
            dc.setCutPercentage(num)
        }

        access(all)
        fun createDrop(nft: @{NonFungibleToken.NFT}, editions: UInt64, minimumBidIncrement: UFix64, minimumBidUniqueIncrement: UFix64, startTime: UFix64, startPrice: UFix64, //TODO: seperate startPrice for unique and edition																																											  
        vaultCap: Capability<&{FungibleToken.Receiver}>, duration: UFix64, extensionOnLateBid: UFix64){ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            ((self.server!).borrow()!).createDrop(nft: <-nft, editions: editions, minimumBidIncrement: minimumBidIncrement, minimumBidUniqueIncrement: minimumBidUniqueIncrement, startTime: startTime, startPrice: startPrice, vaultCap: vaultCap, duration: duration, extensionOnLateBid: extensionOnLateBid)
        }

        /* A stored Transaction to mintArt on versus to a given artist */
        access(all)
        fun mintArt(artist: Address, artistName: String, artName: String, content: String, description: String, type: String, artistCut: UFix64, minterCut: UFix64): @Art.NFT{ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            let artistAccount = getAccount(artist)
            var contentItem <- Content.createContent(content)
            let contentId = contentItem.id

            let content = Versus.account.storage.borrow<&Content.Collection>(from:Content.CollectionStoragePath)!
            content.deposit(token: <-contentItem)
            let contentCapability = Versus.account.capabilities.storage.issue<&Content.Collection>(Content.CollectionStoragePath)

            let artistWallet = artistAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
            let minterWallet = Versus.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
            let royalty ={ "artist": Art.Royalty(wallet: artistWallet, cut: artistCut), "minter": Art.Royalty(wallet: minterWallet, cut: minterCut)}
            let art <- Art.createArtWithPointer(name: artName, artist: artistName, artistAddress: artist, description: description, type: type, contentCapability: contentCapability, contentId: contentId, royalty: royalty)
            return <-art
        }

        access(all)
        fun editionArt(art: &Art.NFT, edition: UInt64, maxEdition: UInt64): @Art.NFT{ 
            return <-Art.makeEdition(original: art, edition: edition, maxEdition: maxEdition)
        }

        access(all)
        fun editionAndDepositArt(art: &Art.NFT, to: [Address]){ 
            let maxEdition: UInt64 = UInt64(to.length)
            var i: UInt64 = 1
            for address in to{ 
                let editionedArt <- Art.makeEdition(original: art, edition: i, maxEdition: maxEdition)
                let account = getAccount(address)
                var collectionCap = account.capabilities.get<&{Art.CollectionPublic}>(Art.CollectionPublicPath)!
                (collectionCap.borrow()!).deposit(token: <-editionedArt)
                i = i + 1 
            }
        }

        access(all)
        fun getContent(): &Content.Collection{ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            return Versus.account.storage.borrow<&Content.Collection>(from: Content.CollectionStoragePath)!
        }

        access(all)
        fun getFlowWallet(): &{FungibleToken.Vault}{ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            return Versus.account.storage.borrow<&{FungibleToken.Vault}>(from: /storage/flowTokenVault)!
        }

        access(all)
        fun getArtCollection(): &{NonFungibleToken.Collection}{ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            return Versus.account.storage.borrow<&{NonFungibleToken.Collection}>(from: Art.CollectionStoragePath)!
        }

        access(all)
        fun getDropCollection(): &Versus.DropCollection{ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            return (self.server!).borrow()!
        }

        access(all)
        fun getVersusProfile(): &Profile.User{ 
            pre{ 
                self.server != nil:
                "Your client has not been linked to the server"
            }
            return Versus.account.storage.borrow<&Profile.User>(from: Profile.storagePath)!
        }
    }

    //make it possible for a user that wants to be a versus admin to create the client
    access(all)
    fun createAdminClient(): @Admin{ 
        return <-create Admin()
    }

    //initialize all the paths and create and link up the admin proxy
    //init is only executed on initial deployment
    init(){ 
        self.CollectionPublicPath = /public/versusCollection
        self.CollectionStoragePath = /storage/versusCollection
        self.VersusAdminPublicPath = /public/versusAdmin
        self.VersusAdminStoragePath = /storage/versusAdmin
        self.totalDrops = 0 
        let account = self.account
        let marketplaceReceiver =
        account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        let marketplaceNFTTrash: Capability<&{Art.CollectionPublic}> =
        account.capabilities.get<&{Art.CollectionPublic}>(Art.CollectionPublicPath)!
        log("Setting up versus capability")
        let collection <-
        create DropCollection(
            marketplaceVault: marketplaceReceiver,
            marketplaceNFTTrash: marketplaceNFTTrash,
            cutPercentage: 0.15
        )
        account.storage.save(<-collection, to: Versus.CollectionStoragePath)
    }
}
