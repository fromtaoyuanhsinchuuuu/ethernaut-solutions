// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

contract DetectionBot is IDetectionBot {
    address public vaultAddress;

    constructor(address _vaultAddress) {
        vaultAddress = _vaultAddress;
    }

    function handleTransaction(address user, bytes calldata msgData) external override {
        // msgData 是 delegateTransfer(address to, uint256 value, address origSender) 的編碼
        // 函數 selector 佔 4 bytes
        // 參數 1 (to) 佔 32 bytes
        // 參數 2 (value) 佔 32 bytes
        // 參數 3 (origSender) 佔 32 bytes -> 這就是我們要的東西，位置在 4 + 32 + 32 = 68 (0x44)
        
        address origSender;
        assembly {
            // 從 msgData 的第 68 個 byte 開始讀取 32 bytes
            // calldataload 是從傳入參數中讀取數據
            // 0x44 是 68 的十六進位
            origSender := calldataload(add(msgData.offset, 0x44))
        }

        if (origSender == vaultAddress) {
            // 如果發現發起者是保險箱，就向 Forta 報警 (Forta 就是 msg.sender)
            IForta(msg.sender).raiseAlert(user);
        }
    }
}
