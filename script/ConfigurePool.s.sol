// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {RebaseTokenPool} from "src/RebaseTokenPool.sol";
import "src/interfaces/IRebaseToken.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {CCIPLocalSimulatorFork, Register} from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RateLimiter} from "lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

contract ConfigurePoolScript is Script{
    
    function run(
        RebaseTokenPool localPool,
        RebaseTokenPool remotePool,
        IRebaseToken remoteToken,
        Register.NetworkDetails memory remoteNetworkDetail
    ) public {
        vm.startBroadcast();

        TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
        // bytes memory remotePoolAddressEthSepolia = new bytes(1);
        bytes memory remotePoolAddressEthSepolia = abi.encode(
            address(remotePool)
        );

        // Here, CCIP will check for:
        // ChainAlreadyExists error -> if we configure token pool twice for same chainId
        // NonExistentChain error -> if allowed is false
        // CursedByRMN error -> if malicious block is present in node
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteNetworkDetail.chainSelector,
            // allowed: false,
            allowed: true, // ensures whether the chain should be enabled or not
            remotePoolAddress: remotePoolAddressEthSepolia,
            remoteTokenAddress: abi.encode(address(remoteToken)),
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            })
        });
        TokenPool(localPool).applyChainUpdates(chains);
        vm.stopBroadcast();
    }
}