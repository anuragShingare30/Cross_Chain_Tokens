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
    event RebaseToken_TokenMinted(address _to, uint256 _amount);

    // modifiers

    // External functions 
    constructor() ERC20("Rebase Token","RBT") Ownable(msg.sender){}

    /** 
        @notice principleBalance function
        @dev The function will return the principle balance/total supply of tokens of user from our parent contract
    */
    function principleBalance(address _user) external returns(uint256){
        return super.balanceOf(_user);
    }

    
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

        emit RebaseToken_TokenMinted(_to, _amount);
    }

    /** 
        @notice burnToken function
        @param _from Address of user from which tokens will burn
        @param _amount amount to mint
        @dev this function decreases the total supply
    */
    function burnToken(address _from, uint256 _amount) external {
        // Transferring or burning Full Balance of user when _amount -> (uint256.max)
        // type(uint256)max -> maximum possible value of uint256
        if(_amount == type(uint256).max){
            _amount = balanceOf(_from);
        }
        mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /** 
        @notice transfer function
        @param _to receiver's address
        @param _amount amount to transfer
        @return Success returns if transfer is valid or not!!!
        @dev Function transfers _amount of token from caller to _to
    */
    function transfer(address _to,uint256 _amount) public override returns(bool){
        if(_amount == type(uint256).max){
            _amount = balanceOf(msg.sender);
        }
        // this will mint the users their token
        // this mint function keep the users balance upto date!!!
        mintAccruedInterest(msg.sender);
        mintAccruedInterest(_to);

        // if user has not deposited into the protocol. their interest rate will be same as of caller's interest rate
        if(balanceOf(_to) == 0){
            s_UsersInterestRate[_to] = s_UsersInterestRate[msg.sender];
        }

        return super.transfer(_to,_amount);
    }

    /** 
        @notice transferFrom function
        @param _to receiver's address
        @param _amount amount to transfer
        @return Success returns if transfer is valid or not!!!
        @dev Function transfers _amount of token from caller to _to
    */
    function transferFrom(address _from,address _to,uint256 _amount) public override returns(bool){
        // check the _amount for max amount of uint256
        if(_amount == type(uint256).max){
            _amount = balanceOf(_from);
        }
        // update the balance of both caller and sender
        mintAccruedInterest(_from);
        mintAccruedInterest(_to);

        // if _to has not deposited/mint previoulsy.
        // set the _to interest rate will be same as _from interest rate
        if(balanceOf(_to) == 0){
            s_UsersInterestRate[_to] = s_UsersInterestRate[_from];
        }
        return super.transferFrom(_from,_to,_amount);
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
        // the main principle balance without the interest rate!!!
        uint256 previousPrincipleBalance = super.balanceOf(_user);

        // the balance of user since last time they call the internal mint function
        // with some interest rate
        uint256 currentBalance = balanceOf(_user);

        // incresedBalance will be the number of token we need to mint more!!!
        uint256 incresedBalance = currentBalance - previousPrincipleBalance;

        // Mint the number of tokens that need to be minted
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