
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Art from 0xf3fcd2c1a78f5eee
import Auction from 0xe03daebed8ca0615


pub contract Versus {
   init() {
        self.totalDrops = UInt64(0)
    }

    pub var totalDrops: UInt64

    //Events
    pub event CollectionCreated(owner:Address, cutPercentage: UFix64)

    //When a drop is extended due to a late bid or bid after tie we emit and event
    pub event DropExtended(id: UInt64, extendWith: UInt64, extendTo: UInt64)

    //When somebody bids on a versus drop we emit and event with the  id of the drop and acution as well as who bid and how much
    pub event Bid(dropId: UInt64, auctionId: UInt64, bidderAddress: Address, bidPrice: UFix64)

    //When a drop is created we emit and event with its id, who owns the art, how many editions are sold vs the unique and the metadata
    pub event DropCreated(id: UInt64, owner: Address, editions: UInt64, metadata: {String: String} )


    pub event Settle(id: UInt64, winner: String, price:UFix64)

    pub fun createVersusDropCollection(
        marketplaceVault: Capability<&{FungibleToken.Receiver}>,
        marketplaceNFTTrash: Capability<&{NonFungibleToken.CollectionPublic}>,
        cutPercentage: UFix64,
        dropLength: UInt64, 
        minimumBlockRemainingAfterBidOrTie: UInt64): @DropCollection {
        let collection <- create DropCollection(
            marketplaceVault: marketplaceVault, 
            marketplaceNFTTrash: marketplaceNFTTrash,
            cutPercentage: cutPercentage,
            dropLength: dropLength,
            minimumBlockRemainingAfterBidOrTie:minimumBlockRemainingAfterBidOrTie
        )
        emit CollectionCreated(owner: marketplaceVault.borrow()!.owner!.address, cutPercentage:cutPercentage)
        return <- collection
    }

    pub resource Drop {

        pub let uniqueAuction: @Auction.AuctionItem
        pub let editionAuctions: @Auction.AuctionCollection
        pub let dropID: UInt64


        init( uniqueAuction: @Auction.AuctionItem, 
            editionAuctions: @Auction.AuctionCollection) { 

            Versus.totalDrops = Versus.totalDrops + UInt64(1)

            self.dropID=Versus.totalDrops
            self.uniqueAuction <-uniqueAuction
            self.editionAuctions <- editionAuctions
        }
            
        destroy(){
            destroy self.uniqueAuction
            destroy self.editionAuctions
        }

        pub fun getDropStatus() : DropStatus {

            let uniqueRef = &self.uniqueAuction as &Auction.AuctionItem
            let editionRef= &self.editionAuctions as &Auction.AuctionCollection

            let editionStatuses= editionRef.getAuctionStatuses()
            var sum:UFix64= UFix64(0)
            for es in editionStatuses.keys {
                sum = sum + editionStatuses[es]!.price
            }
            let uniqueStatus=uniqueRef.getAuctionStatus()
            var price= uniqueStatus.price
            var winningStatus="UNIQUE"
            if(sum > price) {
                winningStatus="EDITIONED"
                price=sum
            } else if (sum == price) {
                winningStatus="TIE"
            }
            return DropStatus(
                dropId: self.dropID,
                uniqueStatus: uniqueStatus,
                editionsStatuses: editionStatuses, 
                editionPrice: sum,
                price: price, 
                status: winningStatus
            )
        }

        pub fun placeBid(
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
            minimumBlockRemaining: UInt64) {

            let dropStatus = self.getDropStatus()
            let currentBlockHeight=getCurrentBlock().height

            if(dropStatus.uniqueStatus.startBlock > currentBlockHeight) {
                panic("The drop has not started")
            }
            if dropStatus.endBlock < currentBlockHeight && dropStatus.winning != "TIE" {
                panic("This drop has ended")
            }
           
            let currentEndBlock = dropStatus.endBlock
            let bidEndBlock = currentBlockHeight + minimumBlockRemaining

            if currentEndBlock < bidEndBlock {
                let extendWith=bidEndBlock - currentEndBlock
                emit DropExtended(id: self.dropID, extendWith: extendWith, extendTo: bidEndBlock)
                self.extendDropWith(extendWith)
            }

            let bidPrice = bidTokens.balance
            let bidder=vaultCap.borrow()!.owner!.address

            if self.uniqueAuction.auctionID == auctionId {
                let auctionRef = &self.uniqueAuction as &Auction.AuctionItem
                auctionRef.placeBid(bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            } else {
                let editionsRef = &self.editionAuctions as &Auction.AuctionCollection 
                editionsRef.placeBid(id: auctionId, bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            }
            emit Bid(dropId: self.dropID, auctionId: auctionId, bidderAddress: bidder , bidPrice: bidPrice)
        }

        pub fun extendDropWith(_ block: UInt64) {
            log("Drop extended with duration")
            log(block)
            self.uniqueAuction.extendWith(block)
            self.editionAuctions.extendAllAuctionsWith(block)
        }
        
    }

    pub struct DropStatus {
        pub let dropId: UInt64
        pub let uniquePrice: UFix64
        pub let editionPrice: UFix64
        pub let endBlock: UInt64
        pub let uniqueStatus: Auction.AuctionStatus
        pub let editionsStatuses: {UInt64: Auction.AuctionStatus}
        pub let price: UFix64
        pub let winning: String

        init(
            dropId: UInt64,
            uniqueStatus: Auction.AuctionStatus,
            editionsStatuses: {UInt64: Auction.AuctionStatus},
            editionPrice: UFix64, 
            price: UFix64,
            status: String //can has enum!
            ) {
                self.dropId=dropId
                self.uniqueStatus=uniqueStatus
                self.editionsStatuses=editionsStatuses
                self.uniquePrice= uniqueStatus.price
                self.editionPrice= editionPrice
                self.endBlock=uniqueStatus.endBlock
                self.price=price
                self.winning=status
            }
    }

    pub resource interface PublicDrop {
         
        pub fun getAllStatuses(): {UInt64: DropStatus}
        pub fun getStatus(dropId: UInt64): DropStatus

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        )

    }

    pub resource DropCollection: PublicDrop {

        pub var drops: @{UInt64: Drop}
        pub var cutPercentage:UFix64 
        pub let marketplaceVault: Capability<&{FungibleToken.Receiver}>
        pub let marketplaceNFTTrash: Capability<&{NonFungibleToken.CollectionPublic}>

        pub let minimumBlockRemainingAfterBidOrTie: UInt64
        pub let dropLength: UInt64


        init(
            marketplaceVault: Capability<&{FungibleToken.Receiver}>, 
            marketplaceNFTTrash: Capability<&{NonFungibleToken.CollectionPublic}>,
            cutPercentage: UFix64,
            dropLength: UInt64,
            minimumBlockRemainingAfterBidOrTie:UInt64
        ) {
            self.marketplaceNFTTrash=marketplaceNFTTrash
            self.cutPercentage= cutPercentage
            self.marketplaceVault = marketplaceVault
            self.dropLength=dropLength
            self.minimumBlockRemainingAfterBidOrTie=minimumBlockRemainingAfterBidOrTie
            self.drops <- {}
        }

        //TODO: different start price for unique and editioned, different bid increment aswell?

        // When creating a drop you send in an NFT and the number of editions you want to sell vs the unique one
        // There will then be minted edition number of extra copies and put into the editions auction
        // When the auction is settled all NFTs that are not sold will be destroyed.
        pub fun createDrop(
             nft: @NonFungibleToken.NFT,
             editions: UInt64,
             minimumBidIncrement: UFix64, 
             startBlock: UInt64, 
             startPrice: UFix64,  
             vaultCap: Capability<&{FungibleToken.Receiver}>) {

            pre {
                vaultCap.check() == true : "Vault capability should exist"
            }

            //copy the metadata of the previous art since that is used to mint the copies
            var metadata=nft.metadata
            let originalMetadata=nft.metadata
            let item <- Auction.createStandaloneAuction(
                token: <- nft,
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: self.dropLength,
                auctionStartBlock: startBlock,
                startPrice: startPrice,
                collectionCap: self.marketplaceNFTTrash,
                vaultCap: vaultCap
            )

            //create the editioned art

            let editionedAuctions <- Auction.createAuctionCollection( 
                marketplaceVault: self.marketplaceVault , 
                cutPercentage: self.cutPercentage)
            metadata["maxEdition"]= editions.toString()
            var currentEdition=UInt64(1)
            while(currentEdition <= editions) {
                metadata["edition"]= currentEdition.toString()
                currentEdition=currentEdition+UInt64(1)
                editionedAuctions.createAuction(
                    token: <- Art.createArt(metadata), 
                    minimumBidIncrement: minimumBidIncrement, 
                    auctionLengthInBlocks: self.dropLength,
                    auctionStartBlock:startBlock,
                    startPrice: startPrice, 
                    collectionCap: self.marketplaceNFTTrash, 
                    vaultCap: vaultCap)
            }
            
            let drop  <- create Drop(uniqueAuction: <- item, editionAuctions:  <- editionedAuctions)
            emit DropCreated(id: drop.dropID, owner: vaultCap.borrow()!.owner!.address, editions: editions,  metadata: originalMetadata )

            let oldDrop <- self.drops[drop.dropID] <- drop
            destroy oldDrop
        }



        pub fun getAllStatuses(): {UInt64: DropStatus} {
            var dropStatus: {UInt64: DropStatus }= {}
            for id in self.drops.keys {
                let itemRef = &self.drops[id] as? &Drop
                dropStatus[id] = itemRef.getDropStatus()
            }
            return dropStatus

        }
        pub fun getStatus(dropId:UInt64): DropStatus {
             pre {
                self.drops[dropId] != nil:
                    "drop doesn't exist"
            }

            // Get the auction item resources
            let itemRef = &self.drops[dropId] as &Drop
            return itemRef.getDropStatus()
        }

        pub fun settle(_ dropId: UInt64) {
           pre {
                self.drops[dropId] != nil:
                    "drop doesn't exist"
            }
            let itemRef = &self.drops[dropId] as &Drop

            if itemRef.uniqueAuction.isAuctionExpired() == false {
                panic("Auction has not completed yet")
            }

            let status=itemRef.getDropStatus()
            let winning=status.winning
            if winning == "UNIQUE" {
                itemRef.uniqueAuction.settleAuction(cutPercentage: self.cutPercentage, cutVault: self.marketplaceVault)
                itemRef.editionAuctions.cancelAllAuctions()
            }else if winning == "EDITIONED" {
                itemRef.uniqueAuction.returnAuctionItemToOwner()
                itemRef.editionAuctions.settleAllAuctions()
            }else {
                panic("tie")
            }
            emit Settle(id: dropId, winner: winning, price: status.price )

        }

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        ) {
            pre {
                self.drops[dropId] != nil:
                    "NFT doesn't exist"

                collectionCap.check() == true : "Collection capability must be linked"

                vaultCap.check() == true : "Vault capability must be linked"

            }
            let drop = &self.drops[dropId] as &Drop
            let minimumBlockRemaining=self.minimumBlockRemainingAfterBidOrTie

            drop.placeBid(auctionId: auctionId, bidTokens: <- bidTokens, vaultCap: vaultCap, collectionCap:collectionCap, minimumBlockRemaining: minimumBlockRemaining)

        }
        destroy() {            
            destroy self.drops
        }
    }
     
}