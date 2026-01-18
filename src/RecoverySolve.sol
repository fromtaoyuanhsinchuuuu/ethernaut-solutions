// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISimpleToken {
    function destroy(address payable _to) external;
}

contract RecoverySolve {
    // 這個合約只是用來存放介面，實際邏輯寫在 Script 裡即可
}
