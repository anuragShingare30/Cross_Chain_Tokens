### What is Rebase tokens?

**Rebase tokens are type of cryptocurrency that have a changing circulating supply, either growing larger (more coins being created/minted) or decreasing (coins get destroyed or 'burnt'), usually to maintain a stable price or achieve a specific target price.**


1. **Traditional tokens**:
    - This have a fixed supply set at the creation of the token. The price of these tokens is determined purely by `market demand and supply dynamics`
  
2. **Rebase tokens**:
    - This are type of crypto-currency. Also called as Elastic token.
    - have a changing circulating supply
    - either growing larger (more coins being created/minted)
    - Or, decreasing (coins get destroyed or 'burnt')
    - can `increase or decrease their supply` automatically!!!




### How Do Rebase Tokens Work?


1. **Target Price & Supply Adjustment**:
   - designed to maintain a `target price` (e.g., $1 per token).
   - If the price goes above the target, `the supply increases` (minting).
   - If the price drops below the target, `the supply decreases` (burning).

2. **Rebasing Mechanism**:
   - At fixed time interval, protocol will check the token price
   - Contract automatically adjusts the total supply of the token depending on the token market price!!!
   - If a rebase reduces supply -> `Users balance decreases`
   - If a rebase increases supply -> `Users balance increases`
   - but their share of the total supply remains the same 


3. **Positive Rebasing**:
   - When the price of token is high relative to its target (say, $1.00) 
   - the protocol automatically increases the supply, distributing more token to all holders proportionally!!!
   - `which theoretically should lower the price`
  
4. **Negative Rebasing**:
   - if the price of token falls below the dollar mark($1)
   - Protocol reducing the number of tokens in each holder's wallet
   - `attempting to increase the price per token`


**Example rebase tokens**:
- Ampleforth (AMPL)
- Yam Finance (YAM)
- Base Protocol (BASE)
- Olympus DAO (OHM)



### What is Blockchain Bridging?

- A protocol that enables the `transfer of tokens/NFTs and information between different blockchain networks`.
- A `blockchain bridge` allows assets, data, or smart contract instructions to move between `different blockchain networks.` 
- Bridging enables DApps and DeFi protocol work on different blockchain network.

**Example**:
-  You have ETH on Ethereum but want to use it on Polygon.
-  A bridge helps you move ETH from Ethereum to Polygon by `locking ETH` on one chain and `minting wrapped ETH` on the other.


**The main concept we can consider in bridging is**:
- `Locking-up` assets on source chain using contract and then `minting their wrapped version` on destination chain!!!

**Transfering data or tokens are done with contract**:
- Source chain and Destination Chain contracts


#### Bridging mechanism

1. **Burn and Mint bridging**:
   - Tokens are burned on the source blockchain
   - an equivalent amount of tokens are minted on the destination blockchain. 
   - total supply of token remain constant


2. **Lock and Mint Bridging**:
   - tokens are locked on the source/issuing blockchain
   - And, `wrapped version` of this tokens is minted in destination chain!!!
   - This wrapped version can be transferred across other non-issuing blockchains using the Burn and Mint mechanism.


3. **Burn and Unlock Bridging**:
   - Tokens are burned on the source blockchain (which is the non-issuing blockchain) 
   - an equivalent amount of tokens are released on the destination blockchain
   - applies when you send tokens back to their issuing source blockchain


4. **Lock and Unlock Bridging**:
   - Tokens are locked on the source blockchain
   - an equivalent amount of tokens are released on the destination blockchain
   - This method is not recommended because, it can result in fragmented liquidity




### Cross Chain Token(CCT) Standard (defines flow)

- **A `Cross-Chain Token Standard` is a set of rules that ensures tokens can move between different blockchains safely and efficiently by leveraging the chainlink CCIP for security**
- `Cross-chain token standards` are just set of rules and instructions that should be followed during transferring tokens cross chain.

**Example**: A stablecoin that seamlessly moves between Ethereum and Polygon.

- Ensures all tokens moving across chains follow the same secure protocol.
- `CCT standard` provides different mechanism for transferring tokens like `burn/mint, lock/unlock`




### Cross Chain Interoperability Protocol (CCIP)


- `Chainlink CCIP` is a system/process that allows smart contracts to `transfer data/assets/tokens` cross-chain
- `CCIP is the bridge` that connects separate blockchains, allowing them to exchange information securely and efficiently.
- It uses `defense-in-depth security` for transfering data/assets cross chain
- `CCIP` uses **Decentralized Oracle network(DON) and Risk management network(RMN)** to check security and transparency for transfering data
- CCIP also inclide `rate limits` for transferring data/assets for security.

**Note: CCIP is performing blockchain bridging in more secure and efficient way as compare to traditional  blockchain bridging!!!**




#### Why Do We Need Chainlink CCIP?

- Ethereum, Binance Smart Chain, and Solana cannot directly exchange tokens or data.
- Traditional blockchain bridges are more `centralized` and need trust on third parties.
- Smart contracts are locked to their chain and cannot access data from other chains.

**CCIP solves this by providing a universal, decentralized, and secure way for blockchains to interact with each other**



#### Chainlink CCIP core capabilities


1. **Arbitrary Messaging**
   - is the ability to `send arbitrary data (encoded as bytes)` to a receiving smart contract on a different blockchain.
   - Send msg from one contract on one chain to other contract on diff chain

2. **Token Transfer**:
   - You can transfer tokens to a smart contract or directly to an metamask wallet(EOA) on a different blockchain. 

3. **Programmable Token Transfer**:
   - simultaneously `transfer tokens and arbitrary data (encoded as bytes)` within a single transaction
   - Data can be instructions on what to do with those tokens.



#### Transferring tokens cross-chain!!!

- Here, we will allow our token on CCIP for transferring cross-chain
- We will follow `burn and mint mechanism` for transferring
- Burn token -> source chain
- Mint token -> destination chain


1. **Deploying Tokens**:
   - Deploy your ERC20 compatible token on 1st chain

2. **Deploying Token Pools**:
   - Once your tokens are deployed, you will deploy Pool contract on 1st and 2nd chain
   - Each token will be linked to a pool, which will manage token transfers and ensure proper handling of assets across chains.

3. **Claiming Mint and Burn Roles**:

4. **Linking Tokens to Pools**:

5. **Minting Tokens**:
   - Mint the token on 1st chain
   - later be used to test cross-chain transfers

6. **Transferring Tokens**:
   - Finally transfer the minted token from 1st chain to 2nd chain using `CCIP`



#### SUMMARY for CCIP

- **CCIP is basically `performing blockchain bridging` in more secure,decentralized and transparent way!!!**
- It works on `DON and RMN`  which relay and validate cross-chain messages.
- It enables `token transfers, smart contract interactions, and seamless multi-chain applications.`
- It's more secure than traditional bridges
- **CCIP is like an advanced version of blockchain bridges, but built for security, scalability, and true interoperability!!!**


**forge install smartcontractkit/ccip@v2.17.0-ccip1.5.16**





### Pool contract

- **These pool contract are essential for minting and burning tokens during cross-chain transfers.**
- Each token will be linked to a pool ,which will manage token transfers and ensure proper handling of assets across chains.
- Pool contract will be granted access for minting and burning during cross-chain transfers.
- Will follow `burnAndMint mechanism` where 
  - burn tokens -> source chain
  - mint token -> destination chain