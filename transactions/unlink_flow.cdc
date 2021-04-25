
transaction() {
    prepare(account: AuthAccount) {    
        //never do this.. extremely dangerous
        log("Unlinking flowTokenReciver for ".concat(account.address.toString()))
        account.unlink(/public/flowTokenReceiver)
  }
}