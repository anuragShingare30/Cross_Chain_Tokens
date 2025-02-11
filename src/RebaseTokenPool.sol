// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
// import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";


/**
 * @title RebaseTokenPool contract
 * @author anurag shingare
 * @notice Pool contract will be responsible for minting and burning token during transfers cross-chain
 * @dev Here we will follow the burnAndMint mechanism
 * @dev BurnToken -> source chain      MintToken -> destination chain
 * @notice CCIP will take care of invalidToken, rate limit, correct chain-id and malicious node that is affected
 * @dev We will follow the below flow for transffering token cross-chain:
    a. Deploy an ERC20 compatible token contract
    b. Deploying Token Pools
    c. Claiming Mint and Burn Roles
    d. Linking Tokens to Pools
    e. Minting Tokens
    f. Transferring Tokens cross chain
 */

contract RebaseTokenPool is TokenPool {
    constructor(
        IERC20 token,
        address[] memory allowlist,
        address rmnProxy,
        address router
    ) TokenPool(token, allowlist, rmnProxy, router) {}



    /// @notice This function will burn the token on source chain
    /// @notice Lock tokens into the pool or burn the tokens.
    /// @param lockOrBurnIn Encoded data fields for the processing of tokens on the source chain. Contains (receiver address, chain-id of destination chain,sender,amount to be send)
    /// @return lockOrBurnOut Encoded data fields for the processing of tokens on the destination chain. Contains destination token address and destPoolData
    /// @dev LockOrBurnInV1 is a struct that contains following params:
    ///     a. recipient of the tokens on the destination chain
    ///     b. The chain ID of the destination chain
    ///     c. The original sender of the tx on the source chain
    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    )
        external
        virtual
        override
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {   
        // This will check for correct supported token
        // Check whether the orcale node is not act malicioulsy
        // Allow the TNX sender in allowlist array
        // Check the correct chain-id for source chain
        // Also, check the rate limit for security
        _validateLockOrBurn(lockOrBurnIn);

        // we will send the userInterestRate as the msg/data cross chain
        // This returns the userAccumulatedInterest before the tokens were burned.
        uint256 userInterestRate = IRebaseToken(address(i_token)).getUserInterestRate(
            lockOrBurnIn.originalSender
        );

        IRebaseToken(address(i_token)).burnToken(address(this), lockOrBurnIn.amount);

        emit Burned(address(this), lockOrBurnIn.amount);

        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            // send any data cross-chain
            destPoolData: abi.encode(userInterestRate)
        }); 
    }


    /// @notice This function will mint the token on destination chain
    /// @notice Releases or mints tokens to the receiver address.
    /// @param releaseOrMintIn All data required to release or mint tokens. Contains sender(bytes), chain-id of source chain, receiver on destination,amount,sourcePoolAddress
    /// @return releaseOrMintOut The amount of tokens released or minted on the destination chain
    
    function releaseOrMint(
    Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
  ) external virtual override returns (Pool.ReleaseOrMintOutV1 memory) {
    
    // Check the token Validity
    // Check for the malicious oracle node
    // Check for correct chain-id of source chain
    // Checks the rate limit
    _validateReleaseOrMint(releaseOrMintIn);

    // This will be the data sent from source chain
    (uint256 userInterestRate) = abi.decode(releaseOrMintIn.sourcePoolData,(uint256));

    // Mint to the receiver
    IRebaseToken(address(i_token)).mintToken(releaseOrMintIn.receiver, releaseOrMintIn.amount);

    emit Minted(msg.sender, releaseOrMintIn.receiver, releaseOrMintIn.amount);

    return Pool.ReleaseOrMintOutV1({destinationAmount: releaseOrMintIn.amount});
  }
}
