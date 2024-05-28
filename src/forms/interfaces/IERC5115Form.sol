// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";

/// @title IERC5115Form
/// @dev Interface for IERC5115Form
/// @author Zeropoint Labs
interface IERC5115Form {
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function getAccruedRewards(address user) external view returns (uint256[] memory rewards);

    function getRewardIndexesStored() external view returns (uint256[] memory indexes);

    function getRewardTokens() external view returns (address[] memory rewardTokens);

    function getYieldToken() external view returns (address yieldToken);

    function getTokensIn() external view returns (address[] memory tokensIn);

    function getTokensOut() external view returns (address[] memory tokensOut);

    function isValidTokenIn(address token) external view returns (bool);

    function isValidTokenOut(address token) external view returns (bool);

    function getTokensOutBalance() external view returns (address[] memory tokensOut, uint256[] memory balances);

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    )
        external
        view
        returns (uint256 amountSharesOut);

    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    )
        external
        view
        returns (uint256 amountTokenOut);

    function getAssetInfo()
        external
        view
        returns (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals);
}
