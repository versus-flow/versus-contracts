transaction(part: String) {
    prepare(signer: AuthAccount) {
        let foo= signer.load<String(from: /storage/uploadArt) //previous
        let path = /storage/upload
        let existing = signer.load<String>(from: path) ?? ""
        signer.save(existing.concat(part), to: path)
    }
}
