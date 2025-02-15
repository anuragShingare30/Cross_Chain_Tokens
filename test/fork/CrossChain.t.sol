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

    // fork id for the source and destination chain
    uint256 ethSepoliaFork;
    uint256 baseSepoliaFork;

    // network details for chain
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
        // this declaration defines that anybody can bridge token
        address[] memory allowlist = new address[](0);

        // set the fork id for chain
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


        ////////////////////////////// 
        // DEPLOY TOKEN AND POOL CONTRACT ON ETH SEPOLIA //
        ////////////////////////////// 

        // GET THE NETWORK DETAILS FOR ETH SEPOLIA
        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.selectFork(ethSepoliaFork);
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

        // ADD SOME REWARDS TO VAULT CONTRACT
        vm.deal(address(vault), 1 ether);

        // GRANT MINT AND BURN ROLE TO VAULT AND POOL CONTRACT
        ethSepoliaToken.grantAccessToMintAndBurnToken(address(ethSepoliaPool));
        ethSepoliaToken.grantAccessToMintAndBurnToken(address(vault));

        // CLAIM ADMIN ROLE
        registryModuleOwnerCustomEthSepolia = RegistryModuleOwnerCustom(
            ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomEthSepolia.registerAdminViaOwner(
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
        // configureTokenPool(ethSepoliaFork, ethSepoliaPool, baseSepoliaPool, IRebaseToken(address(baseSepoliaToken)), baseSepoliaNetworkDetails);
        vm.stopPrank();





        ////////////////////////////// 
        // DEPLOY TOKEN AND POOL CONTRACT ON BASE SEPOLIA //
        ////////////////////////////// 

        vm.selectFork(baseSepoliaFork);
        vm.startPrank(owner);

        // GET THE NETWORK DETAILS FOR BASE SEPOLIA
        baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );

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
        baseSepoliaToken.grantAccessToMintAndBurnToken(
            address(baseSepoliaPool)
        );

        // CLAIM ADMIN ROLE
        registryModuleOwnerCustomBaseSepolia = RegistryModuleOwnerCustom(
            baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        );
        registryModuleOwnerCustomBaseSepolia.registerAdminViaOwner(
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
        // configureTokenPool(baseSepoliaFork, baseSepoliaPool, ethSepoliaPool, IRebaseToken(address(ethSepoliaToken)), ethSepoliaNetworkDetails);
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
        vm.stopPrank();
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

        // Give the user the fee amount in LINK
        // Because of prank the ccipSend function can mess up little bit!!!
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
        vm.warp(block.timestamp + 900);

        uint256 initialBalance_BaseSepolia = IRebaseToken(address(remoteToken)).balanceOf(user);
        console.log("initialBalance_BaseSepolia: ",initialBalance_BaseSepolia);

        // By this method we are changing the fork to base sepolia
        // This function will change the fork to base sepolia and also receive the message send cross-chain
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteForkId);
        uint256 afterBridgingBalance_BaseSepolia = IRebaseToken(address(remoteToken)).balanceOf(user);
        console.log("afterBridgingBalance_BaseSepolia", afterBridgingBalance_BaseSepolia);

        assert(afterBridgingBalance_BaseSepolia == initialBalance_BaseSepolia + amountToBridge);
    }

    function test_BridgeTokens() public {
        // CONFIGURE TOKEN POOL ON SEPOLIA
        configureTokenPool(ethSepoliaFork, ethSepoliaPool, baseSepoliaPool, IRebaseToken(address(baseSepoliaToken)), baseSepoliaNetworkDetails);
        // CONFIGURE TOKEN POOL ON BASE SEPOLIA
        configureTokenPool(baseSepoliaFork, baseSepoliaPool, ethSepoliaPool, IRebaseToken(address(ethSepoliaToken)), ethSepoliaNetworkDetails);

        vm.selectFork(ethSepoliaFork);
        // Pretend a user is interacting with the protocol
        // Give the user some ETH
        // we will bridge 'amount' of amount!!!
        uint256 amount = 1e18;
        vm.startPrank(user);
        vm.deal(user, amount);

        // deposit eth and recieve tokens
        Vault(payable(address(vault))).depositCollateral{value:amount}();
        vm.stopPrank();

        uint256 userBalance = IRebaseToken(address(ethSepoliaToken)).balanceOf(user);
        assert(userBalance == amount);

        // Here we are bridging tokens from ethSepolia to base sepolia
        bridgeToken(amount, ethSepoliaFork, baseSepoliaFork, ethSepoliaNetworkDetails, baseSepoliaNetworkDetails, ethSepoliaToken, baseSepoliaToken);
    }

    function test_BridgeTokenBack() public {
        // configure token pool on sepolia
        configureTokenPool(ethSepoliaFork, ethSepoliaPool, baseSepoliaPool, IRebaseToken(address(baseSepoliaToken)), baseSepoliaNetworkDetails);
        // configure token pool on sepolia
        configureTokenPool(baseSepoliaFork, baseSepoliaPool, ethSepoliaPool, IRebaseToken(address(ethSepoliaToken)), ethSepoliaNetworkDetails);

        vm.selectFork(ethSepoliaFork);
        uint256 amount = 1e18;
        vm.startPrank(user);
        vm.deal(user, amount);

        Vault(payable(address(vault))).depositCollateral{value:amount}();
        uint256 userBalance = IRebaseToken(address(ethSepoliaToken)).balanceOf(user);
        assert(userBalance == amount);
        vm.stopPrank();

        // Bridge token from eth sepolia to base sepolia
        bridgeToken(amount, ethSepoliaFork, baseSepoliaFork, ethSepoliaNetworkDetails, baseSepoliaNetworkDetails, ethSepoliaToken, baseSepoliaToken);


        vm.selectFork(baseSepoliaFork);
        uint256 amountN = 1e18;
        vm.startPrank(user);
        vm.deal(user, amount);
        Vault(payable(address(vault))).depositCollateral{value:amount}();
        uint256 userBalanceN = IRebaseToken(address(baseSepoliaToken)).balanceOf(user);
        assert(userBalanceN == amountN);
        vm.stopPrank();

        // Again, check the bridging from base sepolia to eth sepolia
        bridgeToken(amountN, baseSepoliaFork, ethSepoliaFork, baseSepoliaNetworkDetails, ethSepoliaNetworkDetails, baseSepoliaToken, ethSepoliaToken);

    }
}
