// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {ShopAttack} from "../src/ShopAttack.sol";

contract ShopAttackScript is Script {
    function run() external {
        // 從 .env 讀取實例地址
        address instanceAddress = vm.envAddress("INSTANCE_ADDRESS");

        // 開始廣播交易 (會自動抓取 --account 傳入的簽名者)
        vm.startBroadcast();

        // 1. 部署攻擊合約
        ShopAttack attacker = new ShopAttack(instanceAddress);
        console.log("Attacker deployed at:", address(attacker));

        // 2. 執行攻擊
        attacker.attack();
        console.log("Attack executed!");

        vm.stopBroadcast();
    }
}
