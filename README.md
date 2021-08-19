# Versus Flow Auction Contract

This is a git repo for the cadence contrats for versus@flow. Follow the guide below to set it up and test locally in the terminal.

This project started as a collaboration with 0xAlchemist in his repo https://github.com/0xAlchemist/flow-auction

## Prerequisites

1. Ensure Go is [installed on your machine](https://golang.org/dl/) `recommended version 1.16^`
2. [Install the Flow CLI](https://docs.onflow.org/docs/cli) 
3. Run `$ git clone https://github.com/versus-flow/versus-contracts` in a terminal window
4. Change to the project directory `cd versus-contracts`

## How to run the sample

Start a terminal and run `make demo`

## What happends in the sample

1. install all the contracts
2. setup an artist with a wallet to receive his share
2. setup a marketplace and put a single 1 vs 10 auction active. Marketplace cut is 15%
3. setup bidder1 
4. have bidder1 bid on the auction
5. if you want to you can now start the webpage from the https://github.com/versus-flow/versus-action-website repo to explore the web side 
6. tick the clock and settle the auction
7. settle the auction
8. check all the accounts


## Deploy to testnet

Run `testnet.sh` three times and replace the address for testnet-versus, testnet-admin, testnet-artist with the given addresses. Put the keys safe and export env vars where appropriate

All user facing paths must be incremented for this to work if not old collections that point to old data will be used.
 - Art
 - Marketplace
 - Profile

run `make deploy-testnet` and `make testnet`


