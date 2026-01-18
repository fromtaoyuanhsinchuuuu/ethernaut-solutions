// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HigoToken is ERC20 {
    constructor() ERC20("HigoToken", "HIGO") {
        _mint(msg.sender, 100 * 10**18); // 給自己足夠的量
    }
}
