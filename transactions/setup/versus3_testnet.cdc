


//these are testnet 
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0x467694dd28ef0a12

//This transaction setup of a versus marketplace
//Each drop settlement will deposit cutPercentage number of tokens into the signers vault
//Standard dropLength can be set and the number of seconds to postpone the drops on if there is a late bid

transaction(cutPercentage: UFix64, dropLength: UFix64, minimumTimeRemainingAfterBidOrTie: UFix64) {


    prepare(account: AuthAccount) {
        let marketplaceReceiver=account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let marketplaceNFTTrash=account.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)

        let adminClient=account.borrow<&Versus.VersusAdmin>(from: Versus.VersusAdminClientStoragePath)!

        let versus <- adminClient.createVersusMarketplace(
            marketplaceVault: marketplaceReceiver,
            marketplaceNFTTrash:marketplaceNFTTrash,
            cutPercentage: cutPercentage,
            dropLength: dropLength, 
            minimumTimeRemainingAfterBidOrTie: minimumTimeRemainingAfterBidOrTie
        )

        account.save(<-versus, to: Versus.CollectionStoragePath)
        account.link<&{Versus.PublicDrop}>(Versus.CollectionPublicPath, target: Versus.CollectionStoragePath)
   }
}
 