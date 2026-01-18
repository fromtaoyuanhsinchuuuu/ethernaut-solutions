// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/CoinFlip.sol";

contract AttackScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address instanceAddress = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署攻擊合約（如果還沒部署的話）
        // 這裡可以手動填入已部署的地址，或者每次都部署新的（為了方便示範，我們直接部署）
        CoinFlipAttack attacker = new CoinFlipAttack(instanceAddress);
        
        // 執行一次攻擊
        attacker.makeGuess();

        vm.stopBroadcast();
    }
}
