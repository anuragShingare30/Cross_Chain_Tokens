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