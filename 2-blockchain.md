## General Blockchain
1.  Bob owns a brand new luxurious apartment in Manhattan, New York. Can he use his apartment as collateral for a loan on https://compound.finance/ . If yes, explain how. If no, explain why not?
2. Given that 1 ETH = 1000 USDC. You contributed as a liquidity provider to a Uniswap V2 ETH/USDC pool of 5 ETH and 5000 USDC. The combined value is $10,000. Weeks later, the price of 1 ETH = 1500 USDC. Explain what happens to the funds you contributed to the liquidity provider pool?

## Exploring NFT (Non Fungible Token) using a block explorer

Let’s get additional information about Bored Ape Yacht Club (BAYC), an NFT (Non Fungible Token) project on the Ethereum blockchain.

The BAYC contract address is 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d

Hint: Use Etherscan, an Ethereum block explorer to obtain the information.

1.  What is the metadata for NFT serial #3000 for BAYC? (Hint: The metadata is a json object explaining the attributes of the NFT)  
2.  How many BAYC NFTs are minted in total?  
3.  How many BAYC NFTs does the account 0x49c73c9d361c04769a452e85d343b41ac38e0ee4 hold?  
4.  Who is the owner of NFT serial #3000 for BAYC?  
5.  Is this metadata stored on IPFS or a Cloud Storage? What are the differences, pros and cons?
    

## Contract Calls Knowledge

1.  Using [https://polygon-rpc.com/](https://polygon-rpc.com/) RPC node as a service, write the code and RPC call to obtain `totalSupply` of the [MANA token](https://polygonscan.com/token/0xa1c57f48f0deb89f569dfbe6e2b7f46d33606fd4) issued on the Polygon (MATIC) blockchain. You may consider using the ERC-20 ABI for your solution.
    

## DEX event logs

1.  Given the following USDC/ETH pool on Uniswap V2 [https://v2.info.uniswap.org/pair/0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc](https://v2.info.uniswap.org/pair/0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc), using the Etherscan block explorer, where can I see the list of recent swaps? (You may use screenshot to show your answers)
    
1.  [https://etherscan.io/tx/0x5e555836bacad83ac3989dc1ec9600800c7796d19d706f007844dfc45e9703ac/](https://etherscan.io/tx/0x5e555836bacad83ac3989dc1ec9600800c7796d19d706f007844dfc45e9703ac/) is a swap transaction on a Uniswap V2 pool. One of the associated swaps here is a trade from 1.15481 ETH to $3,184.35. Determine in the block explorer where that raw number is coming from and how it is being derived. (You may use screenshot to show your answers)
    
 1.  Quickswap, a DEX on Polygon (MATIC) allows users to swap two assets as a trade. For every swap transaction that is recorded on the blockchain, a swap event is emitted and stored in the network with this hash ID 0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822. Write the RPC API call to get all the swap events that were emitted for the block [#26444465](https://polygonscan.com/block/26444465). Use [https://polygon-rpc.com/](https://polygon-rpc.com/) RPC node as a service.
    
1.  When using the Quickswap DEX, we noticed that the price impact is -42.09% when we increase the size of the trade. What does price impact mean, why is it important, the math behind the price impact. Include as many details as you can to support your explanation.
