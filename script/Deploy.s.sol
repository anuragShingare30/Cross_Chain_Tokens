// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {RebaseTokenPool} from "src/RebaseTokenPool.sol";
import "src/interfaces/IRebaseToken.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
import {CCIPLocalSimulatorFork, Register} from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";



contract DeployToken is Script{

    RebaseToken rebaseToken;
    RebaseTokenPool tokenPool;
    RegistryModuleOwnerCustom registryModuleOwnerCustomEthSepolia;
    TokenAdminRegistry tokenAdminRegistry;


    function setUp() public returns(RebaseToken,RebaseTokenPool) {
        address[] memory allowlist = new address[](0);
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory tokenNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.startBroadcast();

        rebaseToken = new RebaseToken();
        tokenPool = new RebaseTokenPool(
            IERC20(address(rebaseToken)),
            allowlist,
            tokenNetworkDetails.rmnProxyAddress,
            tokenNetworkDetails.routerAddress
        );
        rebaseToken.grantAccessToMintAndBurnToken(address(tokenPool));
        registryModuleOwnerCustomEthSepolia = RegistryModuleOwnerCustom(
            tokenNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomEthSepolia.registerAdminViaOwner(
            address(rebaseToken)
        );
        tokenAdminRegistry = TokenAdminRegistry(
            tokenNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistry.acceptAdminRole(address(rebaseToken));
        tokenAdminRegistry.setPool(
            address(rebaseToken),
            address(tokenPool)
        );

        vm.stopBroadcast();

        return (rebaseToken,tokenPool);
    }

    function run() public returns(RebaseToken,RebaseTokenPool) {
        return setUp();
    }
}



/**
    * @notice DeployVault script to deploy vault contract on mainnet or testnet
    * @author Anurag shingare
    * @dev Deploy script to deploy vault contract
 */
contract DeployVault is Script{
    
    function run(address _rebaseToken) public returns(Vault){
        vm.startBroadcast();
        Vault vault = new Vault(IRebaseToken((_rebaseToken)));
        IRebaseToken(_rebaseToken).grantAccessToMintAndBurnToken(address(vault));
        vm.stopBroadcast();

        return vault;
    }
}