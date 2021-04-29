transaction(part: String) {
    prepare(signer: AuthAccount) {
        let path = /storage/tmpDropPath
        let existing = signer.load<String>(from: path) ?? ""
        signer.save(existing.concat(part), to: path)
    }
}