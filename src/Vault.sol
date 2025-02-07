// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

/**
 * @title Vault contract
 * @author anurag shingare
 * @notice Vault contract will contain the depositCollateral and redeemCollateral function
 * @dev contract will follow the below flow of protocol:
        a. depositCollateral function will deposit collateral from user and mint the tokens to user.
        b. redeemCollateral function will redeem their tokens for deposited collateral
        c. receive fallback function where contract owner will send some ETH to contract as reward
            - (Optional) user can withdraw ETH as reward depending on amount in vault!!! 
 */

contract Vault {
    ///////////////////////////////////
    //  ERRORS  //
    ///////////////////////////////////
    error Vault_ZeroAmountNotAllowed(uint256 _amount);
    error Vault_NotEnoughBalance(uint256 _amount);
    error Vault_TransactionFailed_RedeemCollateral();


    ///////////////////////////////////
    //  STATE VARIABLES  //
    ///////////////////////////////////
    IRebaseToken public immutable i_rebaseToken;


    ///////////////////////////////////
    //  EVENTS  //
    ///////////////////////////////////
    event Vault_DepositCollateral(address indexed user,uint256 _amount);
    event Vault_RedeemCollateral(address indexed user, uint256 _amount);


    ///////////////////////////////////
    //  MODIFIERS  //
    ///////////////////////////////////
    modifier zeroAmount(){
        if(msg.value <= 0){
            revert Vault_ZeroAmountNotAllowed(msg.value); 
        }
        _;
    }

    ///////////////////////////////////
    // EXTERNAL SENDER FUNCTIONS //
    ///////////////////////////////////
    constructor(IRebaseToken _tokenAddress){
        i_rebaseToken = _tokenAddress;
    }

    /**
        @notice depositCollateral function
        @dev Users will able to deposit ETH and mint rebase tokens
    */
    function depositCollateral() external payable zeroAmount(){
        i_rebaseToken.mintToken(msg.sender, msg.value);
        emit Vault_DepositCollateral(msg.sender, msg.value);
    }

    /**
        @notice redeemCollateral function
        @dev Users will redeem their tokens for collateral
    */
    function redeemCollateral(uint256 _amount) external payable{
        if(i_rebaseToken.balanceOf(msg.sender) < _amount){
            revert Vault_NotEnoughBalance(msg.value);
        }
        if(_amount == type(uint256).max){
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burnToken(msg.sender, msg.value); 

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if(!success){
            revert Vault_TransactionFailed_RedeemCollateral();
        }

        emit Vault_RedeemCollateral(msg.sender,_amount);
    } 


    ///////////////////////////////////
    // EXTERNAL VIEW FUNCTIONS //
    ///////////////////////////////////

    function getTokenAddress() external view returns(IRebaseToken){
        return i_rebaseToken;
    }


    ///////////////////////////////////
    // FALLBACK RECEIEVER FUNCTIONS //
    ///////////////////////////////////

    /**
        @notice receive fallback function
        @dev By this function the protocol owner will able to send ETH to the contract
        @notice (Optional) A mechanism that only gives rewards to the user based on the amount of rewards in the vault
    */
    receive() external payable{}

}