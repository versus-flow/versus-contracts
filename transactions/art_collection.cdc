
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Art from "../contracts/Art.cdc"

//This transaction will prepare the art collection
transaction() {
    prepare(account: AuthAccount) {
        account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)
        account.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)
				account.link<&{NonFungibleToken.CollectionPublic}>(Art.CollectionPublicPathStandard, target: Art.CollectionStoragePath)
    }

}

