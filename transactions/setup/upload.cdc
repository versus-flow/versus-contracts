transaction(part: String) {
    prepare(signer: AuthAccount) {
        let path = /storage/upload
        let existing = signer.load<String>(from: path) ?? ""
        log("length:".concat(existing.length.toString()))
        let new=existing.concat(part)
        signer.save(new, to: path)
        log("newLength:".concat(new.length.toString()))
    }
}