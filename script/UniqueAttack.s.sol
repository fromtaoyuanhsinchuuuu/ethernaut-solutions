// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {UniqueNFTAttacker} from "../src/UniqueNFTAttack.sol";

contract UniqueAttackScript is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address instanceAddr = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署攻擊合約
        UniqueNFTAttacker attacker = new UniqueNFTAttacker(instanceAddr);
        
        vm.stopBroadcast();

        console.log("===========================================");
        console.log("Attacker Contract Deployed At:", address(attacker));
        console.log("===========================================");
        
        return address(attacker);
    }
}
