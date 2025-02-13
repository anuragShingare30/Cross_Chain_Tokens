// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, Vm, console} from "forge-std/Test.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {RebaseTokenPool} from "src/RebaseTokenPool.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
import "src/interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork, Register} from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {IRouterClient} from "lib/ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Client.sol";

contract CrossChainTest is Test {
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
        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString(
            "ETHEREUM_SEPOLIA_RPC_URL"
        );
        string memory BASE_SEPOLIA_RPC_URL = vm.envString(
            "BASE_SEPOLIA_RPC_URL"
        );
        ethSepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL);
        baseSepoliaFork = vm.createFork(BASE_SEPOLIA_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // DEPLOY TOKEN AND POOL CONTRACT ON SEPOLIA
        // GET THE NETWORK DETAILS FOR BASE SEPOLIA
        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        address[] memory allowlist = new address[](0);
        vm.startPrank(owner);
        // DEPLOY TOKEN CONTRACT ON SEPOLIA
        ethSepoliaToken = new RebaseToken();
        // DEPLOY POOL CONTRACT ON SEPOLIA
        ethSepoliaPool = new RebaseTokenPool(
            IERC20(address(ethSepoliaToken)),
            allowlist,
            ethSepoliaNetworkDetails.rmnProxyAddress,
            ethSepoliaNetworkDetails.routerAddress
        );

        // DEPLOY THE VAULT CONTRACT PASS THE TOKEN ADDRESS
        vault = new Vault(IRebaseToken(address(ethSepoliaToken)));

        // GRANT MINT AND BURN ROLE TO VAULT AND POOL
        ethSepoliaToken.grantAccessToMintAndBurnToken(address(vault));
        ethSepoliaToken.grantAccessToMintAndBurnToken(address(ethSepoliaPool));

        // CLAIM ADMIN ROLE
        registryModuleOwnerCustomEthSepolia = RegistryModuleOwnerCustom(
            ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomEthSepolia.registerAdminViaGetCCIPAdmin(
            address(ethSepoliaToken)
        );

        // ACCEPT ADMIN ROLE
        tokenAdminRegistryEthSepolia = TokenAdminRegistry(
            ethSepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistryEthSepolia.acceptAdminRole(address(ethSepoliaToken));

        // LINK TOKEN TO POOL
        tokenAdminRegistryEthSepolia.setPool(
            address(ethSepoliaToken),
            address(ethSepoliaPool)
        );

        // CONFIGURE TOKEN POOL ON SEPOLIA
        vm.stopPrank();

        // DEPLOY TOKEN AND POOL CONTRACT ON BASE SEPOLIA
        vm.selectFork(baseSepoliaFork);
        // GET THE NETWORK DETAILS FOR BASE SEPOLIA
        baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.startPrank(owner);
        // DEPLOY TOKEN CONTRACT
        baseSepoliaToken = new RebaseToken();
        // DEPLOY POOL CONTRACT
        baseSepoliaPool = new RebaseTokenPool(
            IERC20(address(baseSepoliaToken)),
            allowlist,
            baseSepoliaNetworkDetails.rmnProxyAddress,
            baseSepoliaNetworkDetails.routerAddress
        );

        // GRANT MINT AND ADMIN ROLE
        baseSepoliaToken.grantAccessToMintAndBurnToken(address(vault));
        baseSepoliaToken.grantAccessToMintAndBurnToken(
            address(baseSepoliaPool)
        );

        // CLAIM ADMIN ROLE
        registryModuleOwnerCustomBaseSepolia = RegistryModuleOwnerCustom(
            baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomBaseSepolia.registerAdminViaGetCCIPAdmin(
            address(baseSepoliaToken)
        );

        // ACCEPT ADMIN ROLE
        tokenAdminRegistryBaseSepolia = TokenAdminRegistry(
            baseSepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistryBaseSepolia.acceptAdminRole(
            address(baseSepoliaToken)
        );

        // LINK TOKEN TO POOL
        tokenAdminRegistryBaseSepolia.setPool(
            address(baseSepoliaToken),
            address(baseSepoliaPool)
        );

        // CONFIGURE TOKEN POOL ON BASE SEPOLIA
        vm.stopPrank();
    }

    // CONFIGURE TOKEN POOL FUNCTION
    function configureTokenPool(
        uint256 forkId,
        RebaseTokenPool localPool,
        RebaseTokenPool remotePool,
        IRebaseToken remoteToken,
        Register.NetworkDetails memory remoteNetworkDetail
    ) public {
        vm.selectFork(forkId);
        vm.startPrank(owner);

        // CONFIGURE TOKEN POOL
        TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
        bytes memory remotePoolAddressEthSepolia = abi.encodePacked(
            address(remotePool)
        );
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteNetworkDetail.chainSelector,
            allowed: true,
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
        vm.stopPrank();
    }

    function test_BridgeToken() public {
        vm.selectFork(ethSepoliaFork);
        address linkSepolia = ethSepoliaNetworkDetails.linkAddress;
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(user), 20 ether);

        uint256 amountToSend = 100;
        Client.EVMTokenAmount[] memory tokenToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(ethSepoliaToken),
            amount: amountToSend
        });
        tokenToSendDetails[0] = tokenAmount;

        vm.startPrank(user);

        ethSepoliaToken.mintToken(address(user), amountToSend);
        // vault.depositCollateral{value:amountToSend}();

        ethSepoliaToken.approve(
            ethSepoliaNetworkDetails.routerAddress,
            amountToSend
        );
        IERC20(linkSepolia).approve(
            ethSepoliaNetworkDetails.routerAddress,
            20 ether
        );

        uint256 balanceOfUserBeforeBridging_Sepolia = ethSepoliaToken.balanceOf(user);
        console.log("balanceOfUserBeforeBridging_Sepolia:",balanceOfUserBeforeBridging_Sepolia);

        IRouterClient routerEthSepolia = IRouterClient(
            ethSepoliaNetworkDetails.routerAddress
        );
        routerEthSepolia.ccipSend(
            baseSepoliaNetworkDetails.chainSelector,
            Client.EVM2AnyMessage({
                receiver: abi.encode(address(user)),
                data: "",
                tokenAmounts: tokenToSendDetails,
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 0})
                ),
                feeToken: linkSepolia
            })
        );

        uint256 balanceOfUserAfterBridging_Sepolia = ethSepoliaToken.balanceOf(user);
        console.log("balanceOfUserAfterBridging_Sepolia:",balanceOfUserAfterBridging_Sepolia);
        vm.stopPrank();

        assert(balanceOfUserAfterBridging_Sepolia == balanceOfUserBeforeBridging_Sepolia - amountToSend);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseSepoliaFork);

        uint256 balanceOfUserAfterBridging_BaseSepolia = baseSepoliaToken.balanceOf(user);
        console.log("balanceOfUserAfterBridging_BaseSepolia",balanceOfUserAfterBridging_BaseSepolia);
        assert(balanceOfUserAfterBridging_BaseSepolia == amountToSend);
    }


    function bridgeToken(
        uint256 amountToBridge,
        uint256 localForkId,
        uint256 remoteForkId,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        RebaseToken localToken,
        RebaseToken remoteToken
    ) public {

        // Create the message to send tokens cross-chain
        vm.selectFork(localForkId);
        vm.startPrank(user);

        Client.EVMTokenAmount[] memory tokenToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount =
            Client.EVMTokenAmount({token: address(localToken), amount: amountToBridge});
        tokenToSendDetails[0] = tokenAmount;

        // approve the router to burn tokens on behalf of user
        IERC20(address(localToken)).approve(localNetworkDetails.routerAddress,amountToBridge);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user), // we need to encode the address to bytes
            data: "", // We don't need any data for this example
            tokenAmounts: tokenToSendDetails, // this needs to be of type EVMTokenAmount[] as you could send multiple tokens
            extraArgs: "", // We don't need any extra args for this example
            feeToken: localNetworkDetails.linkAddress // The token used to pay for the fee
        });
        vm.stopPrank();

        // Give the user the fee amount of LINK
        ccipLocalSimulatorFork.requestLinkFromFaucet(
            user, IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message)
        );

        vm.startPrank(user);

        IERC20(localNetworkDetails.linkAddress).approve(
            localNetworkDetails.routerAddress,
            IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message)
        ); // Approve the fee

        uint256 balanceOfUserBeforeBridging_Sepolia = IRebaseToken(address(localToken)).balanceOf(user);
        console.log("balanceOfUserBeforeBridging_Sepolia: ",balanceOfUserBeforeBridging_Sepolia);

        // here we send token through bridging!!!
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector, message);

        uint256 balanceOfUserAfterBridging_Sepolia = IRebaseToken(address(localToken)).balanceOf(user);
        console.log("balanceOfUserAfterBridging_Sepolia: ",balanceOfUserAfterBridging_Sepolia);
        
        assert(balanceOfUserAfterBridging_Sepolia == balanceOfUserBeforeBridging_Sepolia - amountToBridge);
        vm.stopPrank();

        vm.selectFork(remoteForkId);
        // lets assume that bridging would take 15-20 minutes to bridge the tokens from source to destination
        vm.warp(block.timestamp + 15 minutes);

        uint256 initialBalance_BaseSepolia = IRebaseToken(address(remoteToken)).balanceOf(user);
        console.log("initialBalance_BaseSepolia",initialBalance_BaseSepolia);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteForkId);
        uint256 afterBridgingBalance_BaseSepolia = IRebaseToken(address(remoteToken)).balanceOf(user);
        console.log(afterBridgingBalance_BaseSepolia);

        assert(afterBridgingBalance_BaseSepolia == initialBalance_BaseSepolia + amountToBridge);
    }

    function test_BridgeTokensFirst() public {
        // CONFIGURE TOKEN POOL ON SEPOLIA
        configureTokenPool(ethSepoliaFork, ethSepoliaPool, baseSepoliaPool, IRebaseToken(address(baseSepoliaToken)), baseSepoliaNetworkDetails);
        // CONFIGURE TOKEN POOL ON BASE SEPOLIA
        configureTokenPool(baseSepoliaFork, baseSepoliaPool, ethSepoliaPool, IRebaseToken(address(ethSepoliaToken)), ethSepoliaNetworkDetails);

        vm.selectFork(ethSepoliaFork);
        // Pretend a user is interacting with the protocol
        // Give the user some ETH
        uint256 amount = 100 ether;
        vm.deal(user, amount);

        vm.startPrank(user);

        // deposit eth and recieve tokens
        vault.depositCollateral{value:amount}();

        vm.stopPrank();

        // bridge tokens
        bridgeToken(100, ethSepoliaFork, baseSepoliaFork, ethSepoliaNetworkDetails, baseSepoliaNetworkDetails, ethSepoliaToken, baseSepoliaToken);
        
    }
}
