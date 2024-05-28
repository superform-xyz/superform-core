// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC5115To4626Wrapper is IStandardizedYield {
    address public immutable vault;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address vault_) {
        vault = vault_;
    }

    //////////////////////////////////////////////////////////////
    //                OVERRIDEN 4626 function                   //
    //////////////////////////////////////////////////////////////

    function asset() external pure returns (address assetTokenAddress) {
        return address(0xDEAD);
    }

    //////////////////////////////////////////////////////////////
    //                    5115 Implementation                   //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IStandardizedYield
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    )
        external
        payable
        returns (uint256 amountSharesOut)
    {
        return IStandardizedYield(vault).deposit(receiver, tokenIn, amountTokenToDeposit, minSharesOut);
    }

    /// @inheritdoc IStandardizedYield
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    )
        external
        returns (uint256 amountTokenOut)
    {
        return IStandardizedYield(vault).redeem(
            receiver, amountSharesToRedeem, tokenOut, minTokenOut, burnFromInternalBalance
        );
    }

    /// @inheritdoc IStandardizedYield
    function exchangeRate() external view returns (uint256 res) {
        return IStandardizedYield(vault).exchangeRate();
    }

    /// @inheritdoc IStandardizedYield
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts) {
        return IStandardizedYield(vault).claimRewards(user);
    }

    /// @inheritdoc IStandardizedYield
    function accruedRewards(address user) external view returns (uint256[] memory rewardAmounts) {
        return IStandardizedYield(vault).accruedRewards(user);
    }

    /// @inheritdoc IStandardizedYield
    function rewardIndexesCurrent() external returns (uint256[] memory indexes) {
        return IStandardizedYield(vault).rewardIndexesCurrent();
    }

    /// @inheritdoc IStandardizedYield
    function rewardIndexesStored() external view returns (uint256[] memory indexes) {
        return IStandardizedYield(vault).rewardIndexesStored();
    }

    /// @inheritdoc IStandardizedYield
    function getRewardTokens() external view returns (address[] memory) {
        return IStandardizedYield(vault).getRewardTokens();
    }

    /// @inheritdoc IStandardizedYield
    function yieldToken() external view returns (address) {
        return IStandardizedYield(vault).yieldToken();
    }

    /// @inheritdoc IStandardizedYield
    function getTokensIn() external view returns (address[] memory res) {
        return IStandardizedYield(vault).getTokensIn();
    }

    /// @inheritdoc IStandardizedYield
    function getTokensOut() external view returns (address[] memory res) {
        return IStandardizedYield(vault).getTokensOut();
    }

    /// @inheritdoc IStandardizedYield
    function isValidTokenIn(address token) external view returns (bool) {
        return IStandardizedYield(vault).isValidTokenIn(token);
    }

    /// @inheritdoc IStandardizedYield
    function isValidTokenOut(address token) external view returns (bool) {
        return IStandardizedYield(vault).isValidTokenOut(token);
    }

    /// @inheritdoc IStandardizedYield
    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    )
        external
        view
        returns (uint256 amountSharesOut)
    {
        return IStandardizedYield(vault).previewDeposit(tokenIn, amountTokenToDeposit);
    }

    /// @inheritdoc IStandardizedYield
    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    )
        external
        view
        returns (uint256 amountTokenOut)
    {
        return IStandardizedYield(vault).previewRedeem(tokenOut, amountSharesToRedeem);
    }

    /// @inheritdoc IStandardizedYield
    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return IStandardizedYield(vault).assetInfo();
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return IStandardizedYield(vault).allowance(owner, spender);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        return IStandardizedYield(vault).approve(spender, value);
    }

    function balanceOf(address account) external view returns (uint256) {
        return IStandardizedYield(vault).balanceOf(account);
    }

    function decimals() external view returns (uint8) {
        return IStandardizedYield(vault).decimals();
    }

    function name() external view returns (string memory) {
        return IStandardizedYield(vault).name();
    }

    function symbol() external view returns (string memory) {
        return IStandardizedYield(vault).symbol();
    }

    function totalSupply() external view returns (uint256) {
        return IStandardizedYield(vault).totalSupply();
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return IStandardizedYield(vault).transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        return IStandardizedYield(vault).transferFrom(from, to, value);
    }
}
