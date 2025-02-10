// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// import {IRebaseToken} from "./interfaces/IRebaseToken.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
import {Pool} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";

contract RebaseTokenPool is TokenPool {
    // errors

    // type declaration

    // state variables

    // events

    // modidfiers

    // functions

    constructor(
        IERC20 token,
        address[] memory allowlist,
        address rmnProxy,
        address router
    ) TokenPool(token,18,allowlist,rmnProxy,router){}



}