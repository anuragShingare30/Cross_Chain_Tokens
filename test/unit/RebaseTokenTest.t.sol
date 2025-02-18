// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console,Vm} from "lib/forge-std/src/Test.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
// import {DeployToken} from "script/Deploy.s.sol";
import "src/interfaces/IRebaseToken.sol";

/**
 * @title Testing Rebase token and Vault contract together
 * @author anurag shingare
 * @dev The flow of protocol will be as:
    a. Owner of contract will set some interest rate
    b. User will deposit collateral(ETH) to mint/borrow Rebasetoken(RBT)
    c. User can redeem tokens for ETH
    d. Protocol will automatically check and mint the accrued interest rate for users deposit
    e. Users can bridge tokens from Eth-Sepolia to Base-Sepolia (For now)
    f. Protocol will automatically interact with Pool and Token contract to maintain the supply of token
 */

contract RebaseTokenTest is Test{
    // error
    error RebaseTokenTest_TransactionTest();

    RebaseToken public rebaseToken;
    Vault public vault;

    address public USER =   makeAddr("user");
    address public NUSER = makeAddr("nuser");
    address public owner = makeAddr("owner");

    function sendRewardToContract() public payable{
        (bool success,) = payable(address(vault)).call{value:1e18}("");
        if(!success){
            revert RebaseTokenTest_TransactionTest();
        }
    }

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantAccessToMintAndBurnToken(address(vault));
        vm.stopPrank();

        // send some amount of ETH to vault contract using low-level instructions
        (bool success,) = payable(address(vault)).call{value:1e18}("");
    }

    ///////////////////////////////////
    // SET INTEREST FUNCTION TEST //
    ///////////////////////////////////

    function test_setInterestRate() public {
        vm.startPrank(owner);
        // set initial interest rate to 10
        rebaseToken.setInterestRate(10);
        uint256 newInterestRate = rebaseToken.getInterestRate();
        console.log(newInterestRate);
        vm.stopPrank();

        // now try to set the new interrest rate
        uint256 prevInterestRate = rebaseToken.getInterestRate();
        vm.startPrank(owner);
        // interest rate will always decrease
        rebaseToken.setInterestRate(prevInterestRate - 1);
        uint256 newIR = rebaseToken.getInterestRate();
        console.log(newIR);
        vm.stopPrank();

        assert(newIR == prevInterestRate-1);
    }

    function test_RevertsIf_InterestRateNotDecreased() public {
        uint256 prevInterestRate = rebaseToken.getInterestRate();
        vm.startPrank(owner);
        vm.expectRevert();
        rebaseToken.setInterestRate(prevInterestRate + 10);
        uint256 newInterestRate = rebaseToken.getInterestRate();
        vm.stopPrank();
    }


    ///////////////////////////////////
    // DEPOSIT FUNCTION TEST //
    ///////////////////////////////////

    function test_userDepositShouldGrowLinearlly() public {
        uint256 amount = 1e18;

        // user will deposit the collateral
        vm.startPrank(USER);
        vm.deal(USER,amount);
        vault.depositCollateral{value:amount}();
        uint256 initInterestRate = rebaseToken.getUserInterestRate(USER);
        uint256 firstBalance = rebaseToken.balanceOf(USER);
        console.log(firstBalance,initInterestRate);
        assert(firstBalance == amount);

        // check the users balance with growing interest rate linearlly!!!
        vm.warp(block.timestamp + 1 days);
        uint256 middleInterestRate = rebaseToken.getUserInterestRate(USER);
        uint256 middleBalance = rebaseToken.balanceOf(USER);
        console.log(middleBalance,middleInterestRate);

        assertGt(middleBalance,firstBalance);
        vm.stopPrank();
    }

    function test_checkTheLinearllyGrowingInterestRateAferMintingActivity() public {
        uint256 amount = 4e18;

        // user will deposit ETH in vault contract
        vm.startPrank(USER);
        vm.deal(USER,amount);

        // first minting
        vault.depositCollateral{value:1e18}();

        uint256 initInterestRate = rebaseToken.getUserInterestRateAccordingToActivity(USER);
        console.log(initInterestRate);

        // second minting
        vault.depositCollateral{value:2e18}();
        vm.warp(block.timestamp + 1 days);

        uint256 finalInterestRate = rebaseToken.getUserInterestRateAccordingToActivity(USER);
        console.log(finalInterestRate);
 
        vm.stopPrank();

        // assertGt(finalInterestRate,initInterestRate);
        console.log("Linearlly growing interest rate: ",finalInterestRate-initInterestRate);
        assertGt(finalInterestRate , initInterestRate);
    }


    ///////////////////////////////////
    // REDEEM COLLATERAL FUNCTION TEST //
    ///////////////////////////////////

    function test_redeemCollateralDirectly() public {
        uint256 amount = 2e18;

        vm.startPrank(USER);
        vm.deal(USER,amount);

        // deposit
        vault.depositCollateral{value:amount}();
        uint256 depositAmount = rebaseToken.balanceOf(USER);
        console.log("Deposited amount:", depositAmount);
        assert(depositAmount == amount);

        // redeem
        vault.redeemCollateral(amount);
        uint256 redeemAmount = rebaseToken.balanceOf(USER);
        console.log("redeemed Amount: ", redeemAmount);

        vm.stopPrank();

        assert(redeemAmount == 0);
    }


    function test_redeemCollateralAfterSomeTime() public {
        uint256 amount = 1e18;

        vm.startPrank(USER);
        vm.deal(USER,amount);

        // deposit
        vault.depositCollateral{value:amount}();
        uint256 balance_after_deposit = rebaseToken.balanceOf(USER);
        console.log("balance_after_deposit:" ,balance_after_deposit);

        // check the balance after some time
        // after passing some time the balance will be increased by some interest rate
        vm.warp(block.timestamp + 1 days);
        uint256 balance_After_Warp_Before_Redeeming = rebaseToken.balanceOf(USER);
        console.log("balance_After_Warp_Before_Redeeming:" ,balance_After_Warp_Before_Redeeming);

        // redeem collateral
        vault.redeemCollateral(amount);

        // After redeeming the remaining balance will be remain with some interest rate!!!
        uint256 Remaining_Balance_After_Redeeming = rebaseToken.balanceOf(USER);
        console.log("Remaining_Balance_After_Redeeming:" ,Remaining_Balance_After_Redeeming);


        vm.stopPrank();

        assert(balance_After_Warp_Before_Redeeming - balance_after_deposit == Remaining_Balance_After_Redeeming);
    }


    ///////////////////////////////////
    // MINTING AND BURNING FUNCTION TEST //
    ///////////////////////////////////

    function test_RevertsIf_NotGrantedRoleForMint() public {
        uint256 amount = 1e18;

        vm.startPrank(USER);
        vm.deal(USER,amount);

        vm.expectRevert();
        rebaseToken.mintToken(USER, amount);
        vm.stopPrank(); 
    }

    function test_RevertsIf_NotGrantedRoleForBurn() public {
        uint256 amount = 1e18;

        vm.startPrank(USER);
        vm.deal(USER,amount);

        vm.expectRevert();
        rebaseToken.mintToken(USER, amount);

        vm.expectRevert();
        rebaseToken.burnToken(USER, amount);
        vm.stopPrank(); 
    }


    ///////////////////////////////////
    // TRANSFER FUNCTION TEST //
    ///////////////////////////////////

    function test_TransferFunction() public {
        uint256 amount = 6e18;

        // userA deposits ETH
        vm.startPrank(USER);
        vm.deal(USER,amount);
        vault.depositCollateral{value:amount}();
        vm.stopPrank();
        
        // Check the users Balance!!!
        uint256 userBalance = rebaseToken.balanceOf(USER);
        uint256 nuserBalance = rebaseToken.balanceOf(NUSER);
        console.log(userBalance,nuserBalance);
        assert(userBalance == amount);
        assert(nuserBalance == 0);

        // set the new interest rate
        // To check the different balance of user
        vm.startPrank(owner);
        rebaseToken.setInterestRate(4e10);
        console.log(rebaseToken.getInterestRate());
        vm.stopPrank();

        // Transfer half amount of tokens to new user
        vm.startPrank(USER);
        uint256 transferAmount = 3e18;
        rebaseToken.transfer(NUSER, transferAmount);
        uint256 userBalance_afterTransfer = rebaseToken.balanceOf(USER);
        uint256 nuserBalance_afterTransfer = rebaseToken.balanceOf(NUSER);
        console.log(userBalance_afterTransfer,nuserBalance_afterTransfer);
        assert(userBalance_afterTransfer == transferAmount);
        assert(nuserBalance_afterTransfer == transferAmount);
        vm.stopPrank();

        // check the interest rate of users before the warp
        uint256 before_userInterestRate = rebaseToken.getUserInterestRateAccordingToActivity(USER);
        uint256 before_nuserInterestRate = rebaseToken.getUserInterestRateAccordingToActivity(NUSER);
        console.log(before_userInterestRate,before_nuserInterestRate);


        // check the users balance after some time
        vm.warp(block.timestamp + 1 days);
        uint256 userBalance_afterTime = rebaseToken.balanceOf(USER);
        uint256 nuserBalance_afterTime = rebaseToken.balanceOf(NUSER);
        console.log(userBalance_afterTime,nuserBalance_afterTime);

        assertGt(userBalance_afterTime,userBalance_afterTransfer);
        assertGt(nuserBalance_afterTime,nuserBalance_afterTransfer);

        // check the interest rate of both user after warp
        uint256 userInterestRate = rebaseToken.getUserInterestRateAccordingToActivity(USER);
        uint256 nuserInterestRate = rebaseToken.getUserInterestRateAccordingToActivity(NUSER);
        console.log(userInterestRate,nuserInterestRate);

        assertGt(userInterestRate,before_userInterestRate);
        assertGt(nuserInterestRate,before_nuserInterestRate);
    }


    ///////////////////////////////////
    // GETTER FUNCTION TEST //
    ///////////////////////////////////

    function test_getInterestRate() public {
        vm.startPrank(USER);
        uint256 interestRate = rebaseToken.getInterestRate();
        vm.stopPrank();
        console.log(interestRate);
    }

    function test_getPrincipleAmountOfUser() public {
        uint256 amount = 1e5;
        vm.startPrank(USER);
        vm.deal(USER, amount);

        vault.depositCollateral{value:amount}();
        uint256 getPrincipleBalance = rebaseToken.principleBalance(USER);
        console.log(getPrincipleBalance);
        vm.stopPrank();

        assert(getPrincipleBalance == amount);

        // check the users principle balance after some time
        vm.startPrank(USER);
        vm.warp(block.timestamp + 1 days);
        uint256 userPrincipleBalance = rebaseToken.principleBalance(USER);
        vm.stopPrank();

        assert(userPrincipleBalance == amount);
    }
}