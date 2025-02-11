// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;


import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @title Basic Rebase token contract
 * @author anurag shingare
 * @dev Rebase token Contract will contain the following functions:
        a. setInterestRate() -> Only owner will able to change the interest rate
        b. mintToken() -> Tokens will be minted only by Pool and Vault contract
        c. burnToken() -> Tokens can burned by Vault and Pool contract
        d. transfer() -> Transfers amount of token from caller to recievers address
        e. transferFrom() -> Moves a `value` amount of tokens from `from` to `to`
        f. balanceOf() -> Returns the linearlly growing balance of user
        g. _calculateUserAccumulatedInterestRateSinceLastTime() -> Returns the linearlly growing interest rate of user. Depends on the last minted activity
        h. _mintAccruedInterest() -> Increase the users balance by some linearlly growing interest rate.
 */


contract RebaseToken is ERC20,Ownable,AccessControl {
    ///////////////////////////////////
    // ERRORS  //
    ///////////////////////////////////
    error RebaseToken_NewInterestRateValueAlwaysDecreases();


    ///////////////////////////////////
    // TYPE DECLARATION  //
    ///////////////////////////////////
    mapping (address user => uint256 usersInterestRate) private s_UsersInterestRate;
    mapping (address user => uint256 lastTimeUsersUpdate) private s_UserLastTimeStamp;


    ///////////////////////////////////
    // STATE VARIABLES  //
    ///////////////////////////////////
    uint256 private s_interestRate = 5e10; // 0.05/sec
    uint256 public constant SCALE_FACTOR = 1e18;
    bytes32 public constant MINT_BURN_ROLE = keccak256("MINT_BURN_ROLE");


    ///////////////////////////////////
    // EVENTS  //
    ///////////////////////////////////
    event RebaseToken_InterestRateSet(uint256 oldValue,uint256 newValue);
    event RebaseToken_TokenMinted(address _to, uint256 _amount);


    ///////////////////////////////////
    // MODIFIERS  //
    ///////////////////////////////////


    ///////////////////////////////////
    // EXTERNAL SENDER FUNCTION  //
    ///////////////////////////////////

    constructor() ERC20("Rebase Token","RBT") Ownable(msg.sender){
        
    }

    /** 
        @notice grantAccessToMintAndBurnToken function
        @param _address user or contract address for minting and burning tokens
        @dev This function will grant the _address to mint and burn token
        @notice This function will be called by Pool and Vault contract!!!
    */
    function grantAccessToMintAndBurnToken(address _address) external onlyOwner(){
        _grantRole(MINT_BURN_ROLE, _address);
    }

    /** 
        @notice principleBalance function
        @dev The function will return the principle balance/total supply of tokens of user from our parent contract
        @dev total supply of tokens of user. This is called to our parent contract ERC20
    */
    function principleBalance(address _user) public view returns(uint256){
        return super.balanceOf(_user);
    }


    /** 
        @notice setInterestRate function
        @dev This function set the new global interest rate for users
        @param _newInterestRate The new rate to be set
    */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner(){
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
        @dev _mintAccruedInterest() function will mint the remaining token for user from lastTimeStamp
    */
    function mintToken(address _to,uint256 _amount) external onlyRole(MINT_BURN_ROLE){
        _mintAccruedInterest(_to);
        s_UsersInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);

        emit RebaseToken_TokenMinted(_to, _amount);
    }

    /** 
        @notice burnToken function
        @param _from Address of user from which tokens will burn
        @param _amount amount to mint
        @dev this function decreases the total supply
        @dev This function will be called by Vault and Pool contract only (IMP.)
    */
    function burnToken(address _from, uint256 _amount) external onlyRole(MINT_BURN_ROLE){
        // Transferring or burning Full Balance of user when _amount -> (uint256.max)
        // type(uint256)max -> maximum possible value of uint256
        if(_amount == type(uint256).max){
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
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
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_to);

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
        _mintAccruedInterest(_from);
        _mintAccruedInterest(_to);

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
        return (currentBalance * _calculateUserAccumulatedInterestRateSinceLastTime(_user))/SCALE_FACTOR;
    }


    ///////////////////////////////////
    // INTERNAL FUNCTION  //
    ///////////////////////////////////

    /** 
        @notice _calculateUserAccumulatedInterestRateSinceLastTime function
        @notice Calculate the interest that has accumulated since the last update!!!
        @param _user receiver address
        @return linearInterest users linearlly growing interest rate
        @notice linearInterest of user will grow after some minting activity.
        @notice Pass some days to see the difference in interest rate of user!!!
    */
    function _calculateUserAccumulatedInterestRateSinceLastTime(address _user) internal view returns(uint256 linearInterest){
        uint256 timeDifference = block.timestamp - s_UserLastTimeStamp[_user];
        // linearInterest -> linear growth over time
        // 1 + (UserInterestRate + timeDifference)
        // This will returns the interest rate for the user based on the previous minting activity
        linearInterest = (timeDifference * s_UsersInterestRate[_user]) + SCALE_FACTOR;
    }


    /**
        @notice _mintAccruedInterest function
        @param _user user address
        @dev Accrued -> Something increased over a period of time!!!
        @dev If totalSupply of token increases daily, the uesrs debt will also increases daily by some x%
        @dev _mintAccruedInterest() will mint rebase token after the supply has been increased!!!
        @dev This function increased the users balance by some linearlly growing interrest rate of users\
        @dev Interest rate of user will grow linearlly when they will start minting
     */
    function _mintAccruedInterest(address _user) internal {
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


    ///////////////////////////////////
    // GETTER CALLABLE FUNCTIONS  //
    ///////////////////////////////////

    function getInterestRate() public view returns(uint256){
        return s_interestRate;
    }
    function getUserInterestRate(address _user) public view returns(uint256) {
        return s_UsersInterestRate[_user];
    }   
    function getUserInterestRateAccordingToActivity(address _user) public view returns(uint256) {
        return _calculateUserAccumulatedInterestRateSinceLastTime(_user);
    }
}