// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GatekeeperOneAttack.sol";

// Inline the Ethernaut GatekeeperOne target for local testing
contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin, "gateOne");
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0, "gateTwo");
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "gateThree-1");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "gateThree-2");
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "gateThree-3");
        _;
    }

    function enter(bytes8 _gateKey)
        external
        gateOne
        gateTwo
        gateThree(_gateKey)
        returns (bool)
    {
        entrant = tx.origin;
        return true;
    }
}

contract GatekeeperTest is Test {
    GatekeeperOne public target;
    GatekeeperOneAttack public attacker;
    address public originUser = address(tx.origin);

    function setUp() public {
        target = new GatekeeperOne();
        attacker = new GatekeeperOneAttack();
    }

    function test_findGasOffset() public {
        // call via attacker; tx.origin spoofed to originUser
        vm.startPrank(originUser, originUser);

        uint256 base = 8191 * 10;
        uint256 foundOffset = type(uint256).max;

        for (uint256 i = 0; i < 8191; i++) {
            bool ok = attacker.attack(address(target), base + i);
            if (ok && target.entrant() == originUser) {
                foundOffset = i;
                break;
            }
        }

        vm.stopPrank();

        assertTrue(foundOffset != type(uint256).max, "no offset found");
        emit log_named_uint("gas offset", foundOffset);
        emit log_named_uint("total gas", base + foundOffset);
    }
}
