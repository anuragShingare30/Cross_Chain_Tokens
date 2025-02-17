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


/**
 * @title CrossChainTest contract
 * @author anurag shingare
 * @notice In this test contract we will perform the complete steps from deploying tokens to bridging tokens cross-chain

 * @dev The Complete start to end flow of this cross-chain bridging protocol is covered below:
    1. Deploying Tokens (RebaseToken contract):
        - Deploy token on eth-sepolia and base-sepolia
        - This contract consist of ERC20 token standard contract
        - Contract contains mintToken, burnToken, grantMintAndBurnRole functions
        - minting-and-burning role will be provided to Vault and Pool contract
        - We will increase the users balance by 0.5% per sec
    2. Deploying Token Pools (RebaseTokenPool contract):
        - Deploy pool contract on eth-sepolia and base-sepolia
        - Contract will inheriting TokenPool contract standard from CCIP
        - Pool contract will follow burn/lock and mint/unlock mechanism
        - Burning on source chain and minting on destination chain
        - Each token will be linked to a pool, which will manage token transfers and ensure proper handling of assets across chains.
    3. Deploy Vault contract (Vault contract)
        - As constructor params pass the address of token contract
    4. Claiming Mint and Burn Roles (grantMintAndBurnRole function):
        - Vault and Pool contract will be assigned the mintAndBurn role
        - allowing your token pools to control how tokens are minted and burned during cross-chain transfers
    5. Claiming and Accepting the Admin Role
        - After this, CCIP will handle all things
        - call the -> 'RegistryModuleOwnerCustom' contract's 'registerAdminViaOwner' function, to enable your token in CCIP
        - After this call -> 'TokenAdminRegistry' contract's 'acceptAdminRole' function to complete registration process.
    6. Linking Tokens to Pools
        - call the 'TokenAdminRegistry' contract's 'setPool' function to associate each token with its respective token pool.
    7. Configuring Token Pools (configureTokenPool)
        - You will call the 'applyChainUpdates' function on your token pools to configure each pool
        - to set cross-chain transfer parameters, such as token pool rate limits and enabled destination chains.
    8. Mint tokens (Vault contract)
        - Call depositCollateral function to borrow some tokens
    
    9. Bridge tokens (bridgeToken function)
        - In this function, we will use CCIP 'setFee' and 'ccipSend' function
        - This function will bridge tokens from source(eth-sepolia) to destination(base-sepolia)
        - this function is responsible to bridge tokens cross-chain!!!!
    @notice The backend workflow of protocol will be:
        1. Setting up CCIP for bridging
        2. Configuring token pool on each chain(set pool, link pool)
        3. Minting/Borrowing rebase token from vault contract
        4. Bridging tokens from source to destination (Using CCIP only) 
 */


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


        // INTIALIZE CCIPLocalSimulatorFork contract instance for testing
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



    ////////////////////////////// 
    // CONFIGURE TOKEN POOL FUNCTION //
    ////////////////////////////// 
    /**
        @notice configureTokenPool function
        @param forkId Chain network forkId
        @param localPool EthSepolia Pool contract 
        @param remotePool baseSepolia Pool contract
        @param remoteToken baseSepolia token contract
        @param remoteNetworkDetail baseSepoia network details
        @notice You will call the 'applyChainUpdates' function on your token pools to configure each pool by setting cross-chain transfer parameters
        @notice CCIP methods and function will handle the correct chainid, non-existent error, chainalready present error
        @dev In this function we will set all imp. params for cross-chain transfering
     */
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



    ////////////////////////////// 
    // BRIDGE TOKEN FUNCTION //
    ////////////////////////////// 
    /**
        @notice bridgeToken function
        @param amountToBridge amounts to bridge from source to destination
        @param localForkId ethsepolia chainid
        @param remoteForkId baseSepolia chainid
        @param localNetworkDetails ethsepolia network details
        @param remoteNetworkDetails baseSepolia network details
        @param localToken ethsepolia token contract
        @param remoteToken baseSepolia token contract
        @notice In this function we will use 'ccipSend' method to transfer token from source to destination
        @notice this function is responsible for bridging token from sourec and destination and vice-versa
     */
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



    /**
        @notice test_BridgeTokens function
        @dev The following test will follow the exact flow whenever user will interact with protocol:
            a. Configure token pool on eth-sepolia and base-sepolia
            b. After configuring, deposit collateral and mint/borrow token
            c. Check initial balance before bridging
            d. Call bridgeToken() -> To bridge token cross-chain
            e. Check userBalance after bridging token
        @notice This function is important for us to understand the flow of complete protocol
        @notice Here, we need to understand that cross-chain bridging is perform by us using either deploy script or this test function
        @notice this test function completely explains how will protocol work in backend
            a. Configuring token pool on both chain
            b. Deploying Eth to borrow token from vault contract
            c. Bridging tokens cross-chain
     */

        // userBalance_BeforeBridging__EthSepolia -> 1e18
        // userBalance_AfterBridging__EthSepolia -> 0
        // userBalance_BeforeBridging__BaseSepolia -> 0
        // userBalance_BeforeBridging__Sepolia -> 1e18
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


    /**
        @notice test_BridgeTokens function
        @dev The following test will follow the exact flow whenever user will interact with protocol:
            a. Configure token pool on eth-sepolia and base-sepolia
            b. After configuring, deposit collateral and mint/borrow token
            c. Check initial balance before bridging
            d. Call bridgeToken() -> To bridge token cross-chain
            e. Check userBalance after bridging token
            f. And, vice-versa!!!
     */
    function test_BridgeTokenBack() public {
        // configure token pool on sepolia
        configureTokenPool(ethSepoliaFork, ethSepoliaPool, baseSepoliaPool, IRebaseToken(address(baseSepoliaToken)), baseSepoliaNetworkDetails);
        // configure token pool on sepolia
        configureTokenPool(baseSepoliaFork, baseSepoliaPool, ethSepoliaPool, IRebaseToken(address(ethSepoliaToken)), ethSepoliaNetworkDetails);


        // bridging eth sepolia to base sepolia!!!
        vm.selectFork(ethSepoliaFork);
        uint256 amount = 1e18;
        vm.deal(user, amount);
        vm.startPrank(user);

        Vault(payable(address(vault))).depositCollateral{value:amount}();
        uint256 userBalance = IRebaseToken(address(ethSepoliaToken)).balanceOf(user);
        assert(userBalance == amount);
        vm.stopPrank();

        // Bridge token from eth sepolia to base sepolia
        bridgeToken(amount, ethSepoliaFork, baseSepoliaFork, ethSepoliaNetworkDetails, baseSepoliaNetworkDetails, ethSepoliaToken, baseSepoliaToken);


        // Bridging back tokens from base sepolia to eth sepolia!!!
        vm.selectFork(baseSepoliaFork);
        vm.warp(block.timestamp + 3600);
        uint256 userBalanceN = IRebaseToken(address(baseSepoliaToken)).balanceOf(user);
        console.log("user destination balance on base sepolia before bridging it back: ", userBalanceN);
        // Again, check the bridging from base sepolia to eth sepolia
        bridgeToken(userBalanceN, baseSepoliaFork, ethSepoliaFork, baseSepoliaNetworkDetails, ethSepoliaNetworkDetails, baseSepoliaToken, ethSepoliaToken);

    }
}
