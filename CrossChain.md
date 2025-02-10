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






### Cross Chain Interoperability Protocol (CCIP)


- `Chainlink CCIP (Cross-Chain Interoperability Protocol)` is a system that allows smart contracts to communicate and `transfer data/tokens` across multiple blockchains
- `CCIP is the bridge` that connects separate blockchains, allowing them to exchange information securely and efficiently.
- **Note**: CCIP is performing blockchain bridging in more secure and efficient way as compare to traditional  blockchain bridging!!!


#### Why Do We Need Chainlink CCIP?

- Ethereum, Binance Smart Chain, and Solana cannot directly exchange tokens or data.
- Traditional blockchain bridges are more centralized and need trust on third parties.
- Smart contracts are locked to their chain and cannot access data from other chains.


**CCIP solves this by providing a universal, decentralized, and secure way for blockchains to interact with each other**


#### How Does Chainlink CCIP Work?

- CCIP uses `Decentralized oracle networks(DON) and Risk Management Network(RMN)` to check the security and transparency to validate the data or message across blockchain!!!!
- CCIP also inclide `rate limits` for transferring data/assets for security.
- This acts as validators and message relayers between blockchains


1. **User Requests Cross-Chain Action**:
   - A smart contract on Blockchain-A wants to send tokens or data to Blockchain-B.
   - The contract sends a request to CCIP

2. **Chainlink Oracles Validate & Relay Data**:
   - A network of decentralized oracles verifies the request.
   - They ensure the transaction is valid, secure, and fraud-proof.

3. **CCIP Sends Data to the Target Blockchain**:
   - After validation, CCIP relays the message or token transfer to Blockchain B.
   - Blockchain B receives the message and executes the smart contract action.

4. **Final Confirmation & Execution**: 
   - Blockchain B confirms the transaction
   - And, executes the requested function (Ex: unlocking tokens, updating records, etc.)



#### Chainlink CCIP core capabilities


1. **Arbitrary Messaging**
   - is the ability to `send arbitrary data (encoded as bytes)` to a receiving smart contract on a different blockchain.
   - Send msg from one contract on one chain to other contract on diff chain

2. **Token Transfer**:
   - You can transfer tokens to a smart contract or directly to an metamask wallet(EOA) on a different blockchain. 

3. **Programmable Token Transfer**:
   - simultaneously `transfer tokens and arbitrary data (encoded as bytes)` within a single transaction
   - Data can be instructions on what to do with those tokens.



#### SUMMARY for CCIP

- **CCIP is basically `performing blockchain bridging` in more secure,decentralized and transparent way!!!**
- It works on DON and RMN  which relay and validate cross-chain messages.
- It enables token transfers, smart contract interactions, and seamless multi-chain applications.
- It's more secure than traditional bridges
- **CCIP is like an advanced version of blockchain bridges, but built for security, scalability, and true interoperability!!!**


**forge install smartcontractkit/ccip@v2.17.0-ccip1.5.16**



### Cross Chain Token-Standard (CCT)

- **An token standard that leverges the chainlink CCIP for transfering data across different blockchain network.**
- `CCT` is built on Chainlink `CCIP` to enable `seamless movement of tokens` between different blockchains without needing custom bridges.
- 