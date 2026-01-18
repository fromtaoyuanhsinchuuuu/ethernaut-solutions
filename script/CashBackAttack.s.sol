// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/// @notice Deploy the adjusted runtime bytecode by combining PREFIX + ADJUSTED_ATTACK_BYTECODE.
contract CashBackAttackScript is Script {
	function run() external {
		bytes memory prefix = vm.envBytes("PREFIX");
		bytes memory adjustedBytecode = vm.envBytes("ADJUSTED_ATTACK_BYTECODE");
		bytes memory runtime = abi.encodePacked(prefix, adjustedBytecode);
		
		require(runtime.length > 0, "runtime missing");
		require(runtime.length <= type(uint16).max, "runtime too long for PUSH2");

		// Minimal init that CODECOPYs the runtime then RETURNs it (header is 14 bytes / 0x0e offset).
		bytes memory init = abi.encodePacked(
			hex"61", bytes2(uint16(runtime.length)), // PUSH2 <len>
			hex"600e", // PUSH1 0x0e (offset past header)
			hex"6000", // PUSH1 0x00 (dest)
			hex"39",   // CODECOPY
			hex"61", bytes2(uint16(runtime.length)), // PUSH2 <len>
			hex"6000", // PUSH1 0x00 (offset)
			hex"f3",   // RETURN
			runtime
		);

		vm.startBroadcast();
		address deployed;
		assembly {
			deployed := create(0, add(init, 0x20), mload(init))
		}
		vm.stopBroadcast();

        console.log("Deployed address:", deployed);
		require(deployed != address(0), "create failed");
	}
}
