// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/FortaBot.sol";


contract SolveDoubleEntryPoint is Script {
    function run() external {
        // 這裡填入你在 Console 查到的地址
        address fortaAddress = 0xcB4d7E1EE30418F7460bf68538268f7069E39b07;
        address vaultAddress = 0x8E87862733f13f0808e74307a18051B205D32b83;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署機器人
        DetectionBot bot = new DetectionBot(vaultAddress);
        console.log("Bot deployed at:", address(bot));

        // 2. 在 Forta 中註冊機器人
        IForta(fortaAddress).setDetectionBot(address(bot));
        console.log("Bot registered in Forta!");

        vm.stopBroadcast();
    }
}
