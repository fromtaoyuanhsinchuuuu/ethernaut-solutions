// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Attacker {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // 讓 Owner 可以把存在這裡的 Token 領回去
    function withdrawToken(address token, uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        IERC20(token).transfer(owner, amount);
    }
}
