// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IRebaseToken {
    function mintToken(address _to,uint256 _amount) external;
    function burnToken(address _from, uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
    function getInterestRate() external view returns(uint256);
    function getUserInterestRate(address _user) external view returns(uint256);
    function grantAccessToMintAndBurnToken(address _address) external;
}