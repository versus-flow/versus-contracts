import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Versus from "../contracts/Versus.cdc"
import Art from "../contracts/Art.cdc"

//This transaction will setup a drop in a versus auction
transaction(
	artist: Address, 
	startPrice: UFix64, 
	startTime: UFix64,
	artistName: String, 
	artName: String,
	description: String, 
	editions: UInt64,
	floorPrice: UFix64, 
	decreasePriceFactor:UFix64,
	decreasePriceAmount:UFix64,
	tickDuration:UFix64,
	artistCut: UFix64,
	minterCut: UFix64,
	type:String
) {


	let client: &Versus.Admin
	let artistWallet: Capability<&{FungibleToken.Receiver}>
	let artistNFTCap: Capability<&{NonFungibleToken.Receiver}>
	let royaltyVaultCap: Capability<&{FungibleToken.Receiver}>
	let content: String

	prepare(account: AuthAccount) {
		let path = /storage/upload
		self.content= account.load<String>(from: path) ?? panic("could not load content")
		self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
		self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		//TODO this needs to be linked before somehow
		self.artistNFTCap=  getAccount(artist).getCapability<&{NonFungibleToken.Receiver}>(/public/versusArtNFTCollection)
		self.royaltyVaultCap= account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
	}

	execute {

		var nftMap : @{UInt64:NonFungibleToken.NFT} <- {}
		var i =(0 as UInt64)

		//I use a string:string here so that we can add other information and are not bound to a speicify NFTs type of metadata
		var metadata: { String:String}={}
		while i < editions {
			let art <-  self.client.mintArt(artist: artist,
			artistName: artistName,
			artName: artName,
			content:self.content,
			description: description, 
			type: type,
			artistCut: artistCut, 
			minterCut:minterCut)

			if i == 0 {
				let artData=art.metadata
				metadata["nftType"] = art.getType().identifier
				metadata["name"] = artData.name
				metadata["artist"] = artData.artist
				metadata["artistAddress"] = artData.artistAddress.toString()
				metadata["description"] = artData.description
				metadata["type"] = artData.type
				metadata["contentId"] = art.contentId?.toString() ?? ""
				metadata["url"] = art.url ?? ""

			}
			nftMap[art.id] <-! art
			i=i+1
		}
		self.client.createAuctionDutch(nfts: <- nftMap,
		metadata: metadata,
		startAt: startTime,
		startPrice: startPrice,
		floorPrice: floorPrice,
		decreasePriceFactor: decreasePriceFactor,
		decreasePriceAmount: decreasePriceAmount,
		tickDuration: tickDuration,
		ownerVaultCap: self.artistWallet,
		ownerNFTCap: self.artistNFTCap,
		royaltyVaultCap: self.royaltyVaultCap,
		royaltyPercentage: minterCut)
	}
}
