### CONTRACT COVERAGE REPORT

# Code Coverage Report

| File                    | % Lines         | % Statements    | % Branches    | % Funcs         |
|-------------------------|----------------|----------------|--------------|----------------|
| `script/Deploy.s.sol`   | 0.00% (0/8)     | 0.00% (0/9)     | 100.00% (0/0) | 0.00% (0/2)     |
| `src/RebaseToken.sol`   | 94.55% (52/55)  | 94.44% (51/54)  | 57.14% (4/7)  | 100.00% (13/13) |
| `src/RebaseTokenPool.sol` | 100.00% (12/12) | 100.00% (12/12) | 100.00% (0/0) | 100.00% (2/2)   |
| `src/Vault.sol`         | 70.00% (14/20)  | 70.59% (12/17)  | 0.00% (0/4)   | 80.00% (4/5)    |
| **Total**               | **82.11% (78/95)**  | **81.52% (75/92)**  | **36.36% (4/11)** | **86.36% (19/22)**  |



**Note: To understand complete flow of protocol and bridging of tokens refer test_BridgeToken() function in test/CrossChain.t.sol file!!!**


### ABOUT PROJECT

1. An DeFi protocol for Rebase token system
2. User can deposit ETH to mint/borrow rebase token(RBT) and redeem ETH for tokens
3. User will gain a increase of 0.5% per sec of balance as accrued interest rate!!!
4. User can bridge RebaseTokens(RBT) from Eth-sepolia to base-sepolia and vice-versa


### Final Result :

1. `userBalance_BeforeBridging__EthSepolia` -> 1e18
2. `userBalance_AfterBridging__EthSepolia` -> 0
3. `userBalance_BeforeBridging__BaseSepolia` -> 0
4. `userBalance_BeforeBridging__Sepolia` -> 1e18




### Important Contract and Its function


1. **RebaseToken Contract**
   - An ERC20 compatible contract
   - Protocol will interact with this contract!!!
   - Grant the mint and burn role to Vault and Pool contract
   - Contain mint,burn and grantMintAndBurnRole functions

2. **Vault Contract:**
   - User will interact with contract
   - User can depositCollateral and borrow rebase token(RBT)
   - User can redeemCollateral for tokens
   - Contains deposit and Redeem collateral function

3. **RebaseTokenPool Contract**:
   - Protocol will interact with this contract!!!
   - Protocol will handle the burn and mint mechanism during bridging
   - Contains lockOrBurn and unlockOrMint function


4. **Bridging tokens cross-chain**:
   - Will use `CCIP` to handle the tokens bridging cross-chain
   - **Refer test_BridgeToken function in CrossChain.t.sol file**




### Bridging token cross-chain using chainlink CCIP!!!


- `CCIP` will specifically look for bridging tokens cross-chain
- **We will bridge rebase token from eth-sepolia to base-sepolia**
- will follow the below flow for bridging:



1. **Deploy Rebase Tokens**:
   - `RebaseToken Contract` is ERC20 compatible contract
   - Deploy rebase token on eth-sepolia and base-sepolia
   - Contains *mint,burn,grantMintAndBurnRole function*

2. **Deploying Token Pools**:
   - Deploy `RebaseTokenPool contract` on both eth-sepolia and base-sepolia chain
   - These pools are essential for minting and burning tokens during cross-chain bridging.
   - Each token will be linked to a pool, which will manage token transfers
   - Contains *lockOrBurn and UnlockOrMint function*

3. **Deploy Vault contract**:
   - Deploy vault contract
   - Contains *depositCollateral,redeemCollateral functions*


4. **Claiming Mint and Burn Roles**:
   - Grant mint and burn role to `Vault and Pool contract`

5. **Claiming and Accepting the Admin Role**:
   -  `registerAdminViaOwner function` to register our EOA as the token admin and register our token on `CCIP`
   -  `acceptAdminRole function` to complete the registration process.


6. **Linking Tokens to Pools**:
   - `setPool function` to associate each token with its respective token pool.

7. **Configuring Token Pools**:
   - `applyChainUpdates function` on your token pools to configure each pool by setting cross-chain transfer parameters to enable chain

8. **Deploy token on vault**:
   - On Vault contract -> call depositCollateral to borrow rebase token
   - This will be done before bridging.
   - We will bridge the rebase token from eth-sepolia to base-sepolia

9. **Transferring/Bridging Tokens**:
   - Will use `EVM2AnyMessage(), getFee(), ccipSend() function` to bridge token cross-chain
   - `CCIP` will take care of bridging token





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


#### Different Bridging mechanism

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




### Cross Chain Token(CCT) Standard (defines flow of contract)

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



### Pool contract

- **These pool contract are essential for minting and burning tokens during cross-chain transfers.**
- Each token will be linked to a pool ,which will manage token transfers and ensure proper handling of assets across chains.
- Pool contract will be granted access for minting and burning during cross-chain transfers.
- Will follow `burnAndMint mechanism` where 
  - burn tokens -> source chain
  - mint token -> destination chain



### Docs Sources

1. **Cross-Chain Token (CCT) standard**
   - https://docs.chain.link/ccip/concepts/cross-chain-tokens 

2. **CCIP Conceptual Overview**
   - https://docs.chain.link/ccip/concepts#overview 

3. **What is Rebase token?**
   - https://cryptotaxcalculator.io/us/guides/rebase-tokens/
   - https://kauri.finance/academy/what-are-rebase-tokens

4. **An complete overview of working of our DeFi protocol for token transfer cross-chain**:
   - https://docs.chain.link/ccip/tutorials/cross-chain-tokens/register-from-eoa-burn-mint-foundry#overview 

5. **Local testing of tokens Bridging and Pool contract**:
   - https://docs.chain.link/chainlink-local/build/ccip/foundry/cct-burn-and-mint-fork#step-2-deploy-token-on-base-sepolia
