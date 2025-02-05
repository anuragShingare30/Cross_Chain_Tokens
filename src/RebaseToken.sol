// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;


import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Basic Rebase token contract
 * @author anurag shingare
 * @dev Always update the time stamp of user whenever minting,burning,transfer,bridging is called!!!
 */


contract RebaseToken is ERC20,Ownable {
    // errors
    error RebaseToken_NewInterestRateValueAlwaysDecreases();

    // type declaration
    mapping (address user => uint256 usersInterestRate) private s_UsersInterestRate;
    mapping (address user => uint256 lastTimeUsersUpdate) private s_UserLastTimeStamp;

    // state variables
    uint256 private s_interestRate;
    uint256 public constant SCALE_FACTOR = 1e18;

    // events
    event RebaseToken_InterestRateSet(uint256 oldValue,uint256 newValue);

    // modifiers

    // External functions 
    constructor() ERC20("Rebase Token","RBT") Ownable(msg.sender){}


    /** 
        @notice setInterestRate function
        @dev This function set the new global interest rate for users
        @param _newInterestRate The new rate to be set
    */
    function setInterestRate(uint256 _newInterestRate) external{
        if(_newInterestRate >= s_interestRate){
            revert RebaseToken_NewInterestRateValueAlwaysDecreases();
        }
        s_interestRate = _newInterestRate;
        emit RebaseToken_InterestRateSet(s_interestRate,_newInterestRate);
    }

    /** 
        @notice mintToken function
        @dev This function creates/mint the rebase tokens
        @param _to receiver address
        @param _amount amount to mint
        @dev This function will be called by Vault and Pool contract only (IMP.)
        @dev mintAccruedInterest() function will mint the remaining token for user from lastTimeStamp
    */
    function mintToken(address _to,uint256 _amount) external {
        mintAccruedInterest(_to);
        s_UsersInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /** 
        @notice balanceOf function
        @param _user user/receiver address
        @return AccruedBalanceOfUser returns the accrued balance of user.
        @dev (principleBalance * linearInterestRate)
        @dev Function will calculate the linearlly growing balance of user
    */
    function balanceOf(address _user) public view override returns(uint256) {
        uint256 currentBalance = super.balanceOf(_user);
        if(currentBalance == 0){
            return 0;
        }
        // (currentBalance * linearInterestRate)
        return (currentBalance * calculateUserAccumulatedInterestRateSinceLastTime(_user))/SCALE_FACTOR;
    }


    // internal functions

    /** 
        @notice calculateUserAccumulatedInterestRateSinceLastTime function
        @notice Calculate the interest that has accumulated since the last update!!!
        @param _user receiver address
        @return linearInterest  users linearlly growing interest rate
    */
    function calculateUserAccumulatedInterestRateSinceLastTime(address _user) internal view returns(uint256 linearInterest){
        uint256 timeDifference = block.timestamp - s_UserLastTimeStamp[_user];
        // linearInterest -> linear growth over time
        // 1 + (UserInterestRate + timeDifference)
        linearInterest = (timeDifference * s_UsersInterestRate[_user]) + SCALE_FACTOR;
    }


    /**
        @notice mintAccruedInterest function
        @param _user user address
        @dev Accrued -> Something increased over a period of time!!!
        @dev If totalSupply of token increases daily, the uesrs debt will also increases daily by some x%
        @dev mintAccruedInterest() will mint rebase token after the supply has been increased!!!
     */
    function mintAccruedInterest(address _user) internal {
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);

        // incresedBalance will be the number of token we need to mint more!!!
        uint256 incresedBalance = currentBalance - previousPrincipleBalance;

        // mint increased token
        _mint(_user, incresedBalance);

        // update the users time stamp during minting
        s_UserLastTimeStamp[_user] = block.timestamp;
    }


    // getter functions
    function getInterestRate() public view returns(uint256){
        return s_interestRate;
    }
    function getUserInterestRate(address _user) public view returns(uint256) {
        return s_UsersInterestRate[_user];
    }   
}