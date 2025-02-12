// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Test, Vm,console } from "forge-std/Test.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {RebaseTokenPool} from "src/RebaseTokenPool.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
import "src/interfaces/IRebaseToken.sol";
import { CCIPLocalSimulatorFork, Register } from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";


contract CrossChainTest is Test{
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;

    uint256 ethSepoliaFork;
    uint256 baseSepoliaFork;

    Register.NetworkDetails ethSepoliaNetworkDetails;
    Register.NetworkDetails baseSepoliaNetworkDetails;

    // for claiming role
    RegistryModuleOwnerCustom registryModuleOwnerCustomEthSepolia;
    RegistryModuleOwnerCustom registryModuleOwnerCustomBaseSepolia;

    // for accepting admin role
    TokenAdminRegistry tokenAdminRegistryEthSepolia;
    TokenAdminRegistry tokenAdminRegistryBaseSepolia;

    // create token contract instance for both source and destiantion
    RebaseToken ethSepoliaToken;
    RebaseToken baseSepoliaToken;

    // create pool contract instance
    RebaseTokenPool ethSepoliaPool;
    RebaseTokenPool baseSepoliaPool;

    // contract instance for vault contract
    Vault vault;


    function setUp() public {

        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory BASE_SEPOLIA_RPC_URL = vm.envString("BASE_SEPOLIA_RPC_URL");
        ethSepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL);
        baseSepoliaFork = vm.createFork(BASE_SEPOLIA_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // deploy token and pool contract on eth-sepolia
        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        address[] memory allowlist = new address[](0);
        vm.startPrank(owner);
        // deploy token contract
        ethSepoliaToken = new RebaseToken();
        // deploy pool conmtract
        ethSepoliaPool = new RebaseTokenPool(
            IERC20(address(ethSepoliaToken)),
            allowlist,
            ethSepoliaNetworkDetails.rmnProxyAddress,
            ethSepoliaNetworkDetails.routerAddress
        );

        // grant mint and burn role to vault and pool contract
        ethSepoliaToken.grantAccessToMintAndBurnToken(address(vault));
        ethSepoliaToken.grantAccessToMintAndBurnToken(address(ethSepoliaPool));

        // claim admin role
        registryModuleOwnerCustomEthSepolia = RegistryModuleOwnerCustom(
            ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomEthSepolia.registerAdminViaGetCCIPAdmin(address(ethSepoliaToken));

        // accept admin role
        tokenAdminRegistryEthSepolia = TokenAdminRegistry(
            ethSepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistryEthSepolia.acceptAdminRole(address(ethSepoliaToken));

        // link token to pool
        tokenAdminRegistryEthSepolia.setPool(address(ethSepoliaToken), address(ethSepoliaPool));

        // configure token pool on sepolia
        TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
        bytes[] memory remotePoolAddressesEthSepolia = new bytes[](1);
        remotePoolAddressesEthSepolia[0] = abi.encode(address(ethSepoliaPool));
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: baseSepoliaNetworkDetails.chainSelector,
            allowed:true,
            remotePoolAddresses: remotePoolAddressesEthSepolia,
            remoteTokenAddress: abi.encode(address(ethSepoliaToken)),
            outboundRateLimiterConfig: RateLimiter.Config({ isEnabled: false, capacity: 0, rate: 0 }),
            inboundRateLimiterConfig: RateLimiter.Config({ isEnabled: false, capacity: 0, rate: 0 })
        });
        uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);
        ethSepoliaPool.applyChainUpdates(chains);
        vm.stopPrank();




        // deploy token and pool contract on base-sepolia
        vm.selectFork(baseSepoliaFork);
        baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        baseSepoliaToken = new RebaseToken();
        baseSepoliaPool = new RebaseTokenPool(
            IERC20(address(baseSepoliaToken)),
            allowlist,
            baseSepoliaNetworkDetails.rmnProxyAddress,
            baseSepoliaNetworkDetails.routerAddress
        );

        // grant mint and burn roles
        baseSepoliaToken.grantAccessToMintAndBurnToken(address(vault));
        baseSepoliaToken.grantAccessToMintAndBurnToken(address(baseSepoliaPool));

        // claim admin role
        registryModuleOwnerCustomBaseSepolia = RegistryModuleOwnerCustom(
            baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomBaseSepolia.registerAdminViaGetCCIPAdmin(address(baseSepoliaToken));

        // accept admin role
        tokenAdminRegistryBaseSepolia = TokenAdminRegistry(
            baseSepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistryBaseSepolia.acceptAdminRole(address(baseSepoliaToken));

        // link token to pool
        tokenAdminRegistryBaseSepolia.setPool(address(baseSepoliaToken), address(baseSepoliaPool));

        // configure token pool on base sepolia
        chains = new TokenPool.ChainUpdate[](1);
        bytes[] memory remotePoolAddressesBaseSepolia = new bytes[](1);
        remotePoolAddressesBaseSepolia[0] = abi.encode(address(baseSepoliaPool));
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: ethSepoliaNetworkDetails.chainSelector,
            allowed:true,
            remotePoolAddresses: remotePoolAddressesBaseSepolia,
            remoteTokenAddress: abi.encode(address(baseSepoliaToken)),
            outboundRateLimiterConfig: RateLimiter.Config({ isEnabled: false, capacity: 0, rate: 0 }),
            inboundRateLimiterConfig: RateLimiter.Config({ isEnabled: false, capacity: 0, rate: 0 })
        });
        baseSepoliaPool.applyChainUpdates(chains);

        vm.stopPrank();

    }
}