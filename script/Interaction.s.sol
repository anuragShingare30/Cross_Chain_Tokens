// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Vault} from "src/Vault.sol";

contract DeployDeposit is Script{

    uint256 public constant amount = 2e16;

    function deposit(address vault) public payable{
        Vault(payable(vault)).depositCollateral{value:amount}();
    }

    function run(address vault) external payable{
        deposit(vault);
    }

}


contract DeployRedeem is Script{

    uint256 public constant amount = 2e16;

    function redeem(address vault) public payable{
        Vault(payable(vault)).redeemCollateral(type(uint256).max);
    }

    function run(address vault) external payable{
        redeem(vault);
    }

}