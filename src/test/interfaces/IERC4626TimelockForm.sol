///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {InitSingleVaultData} from "../../types/DataTypes.sol";

interface IERC4626TimelockForm is IERC20 {
    /// @notice Getter for returning singleVaultData from the Form to the FormKeeper
    /// TODO: We use two IERC4626TimelockForm interfaces (files), should be only one!
    function unlockId(uint256 unlockCounter) external view returns (InitSingleVaultData memory singleVaultData);

    function vaultSharesIsERC20() external pure returns (bool);

    function vaultSharesIsERC4626() external pure returns (bool);

    function getVaultAsset() external view returns (address);

    function getVaultName() external view returns (string memory);

    function getVaultSymbol() external view returns (string memory);

    function getVaultDecimals() external view returns (uint256);

    function getPricePerVaultShare() external view returns (uint256);

    function getVaultShareBalance() external view returns (uint256);

    function getTotalAssets() external view returns (uint256);

    function getConvertPricePerVaultShare() external view returns (uint256);

    function getPreviewPricePerVaultShare() external view returns (uint256);

    function previewDepositTo(uint256 assets_) external view returns (uint256);

    function previewWithdrawFrom(uint256 assets_) external view returns (uint256);
}
