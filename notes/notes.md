# Notes and Questions

## Setup - Done

1. Account 1 has 100 DemoToken and 10 NFTs
2. Account 2 has 200 DemoToken and 0 NFTs
3. Account 3 has 200 DemoToken and 0 NFTs
4. Account 4 has 200 DemoToken and 0 NFTs

## Auction

1. (*) Account 1 adds all 10 NFTs to the auction queue
2. The NFT with the highest ID number is first up for auction
3. Any accounts may bid on the active auction
4. Bidders receive an AuctionBallot FT after a successful bid
5. AuctionBallot holders can vote on which NFT from the auction queue becomes available next
6. The NFT with the highest vote count is placed up for auction
7. If all votes are equal, the NFT with the highest ID number is placed up for auction
8. This process continues until the auction queue is empty
