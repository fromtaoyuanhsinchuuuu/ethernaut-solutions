// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPuzzle {
    // Proxy functions
    function proposeNewAdmin(address _newAdmin) external;
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);

    // Wallet functions
    function owner() external view returns (address);
    function whitelisted(address) external view returns (bool);
    function addToWhitelist(address addr) external;
    function deposit() external payable;
    function multicall(bytes[] calldata data) external payable;
    function execute(address to, uint256 value, bytes calldata data) external payable;
    function setMaxBalance(uint256 _maxBalance) external;
    function balances(address) external view returns (uint256);
}
