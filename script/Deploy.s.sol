// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
import "src/interfaces/IRebaseToken.sol";
import "lib/forge-std/src/Vm.sol";

contract DeployToken is Script{

    IRebaseToken i_rebaseToken;

    function setUp(address _tokenAddress) public returns(RebaseToken rebaseToken,Vault vault){
        vm.startBroadcast();
        RebaseToken rebaseToken = new RebaseToken();
        Vault vault = new Vault(IRebaseToken(_tokenAddress));
        vm.stopBroadcast();

        return (rebaseToken,vault);
    }

    function run() external returns(RebaseToken,Vault){
        address _tokenAddress;
        // address getMostRecentDeployedContractAddress;
        return setUp(_tokenAddress);
    }
}