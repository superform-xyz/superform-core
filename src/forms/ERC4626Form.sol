// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {LiquidityHandler} from "../crosschain-liquidity/LiquidityHandler.sol";
import {StateData, TransactionType, CallbackType, FormData, FormCommonData, FormXChainData, XChainActionArgs, ReturnData} from "../types/DataTypes.sol";
import {LiqRequest} from "../types/LiquidityTypes.sol";
import {BaseForm} from "../BaseForm.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {ERC20Form} from "./ERC20Form.sol";

/// @title ERC4626Form
/// @notice The Form implementation for ERC4626 vaults
contract ERC4626Form is ERC20Form, LiquidityHandler {
    using SafeTransferLib for ERC20;

    constructor(
        uint80 chainId_,
        IBaseStateRegistry stateRegistry_,
        ISuperFormFactory superformfactory_
    ) ERC20Form(chainId_, stateRegistry_, superformfactory_) {}

    /*///////////////////////////////////////////////////////////////
                            VIEW/PURE OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function vaultSharesIsERC20() public pure virtual override returns (bool) {
        return false;
    }

    /// @inheritdoc BaseForm
    function vaultSharesIsERC4626()
        public
        pure
        virtual
        override
        returns (bool)
    {
        return true;
    }

    /// @inheritdoc BaseForm
    /// @dev asset() or some similar function should return all possible tokens that can be deposited into the vault so that BE can grab that properly
    function getUnderlyingOfVault(
        address vault_
    ) public view virtual override returns (ERC20) {
        return ERC4626(vault_).asset();
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare(
        address vault_
    ) public view virtual override returns (uint256) {
        uint256 vaultDecimals = ERC4626(vault_).decimals();
        return ERC4626(vault_).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance(
        address vault_
    ) public view virtual override returns (uint256) {
        return ERC4626(vault_).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets(
        address vault_
    ) public view virtual override returns (uint256) {
        return ERC4626(vault_).totalAssets();
    }

    /// @inheritdoc BaseForm
    function getConvertPricePerVaultShare(
        address vault_
    ) public view virtual override returns (uint256) {
        uint256 vaultDecimals = ERC4626(vault_).decimals();
        return ERC4626(vault_).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare(
        address vault_
    ) public view virtual override returns (uint256) {
        uint256 vaultDecimals = ERC4626(vault_).decimals();
        return ERC4626(vault_).previewRedeem(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(
        address vault_,
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return ERC4626(vault_).convertToShares(assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(
        address vault_,
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return ERC4626(vault_).previewWithdraw(assets_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        bytes calldata formData
    ) internal virtual override returns (uint256[] memory dstAmounts) {
        FormData memory data = abi.decode(formData, (FormData));

        FormCommonData memory commonData = abi.decode(
            data.commonData,
            (FormCommonData)
        );

        LiqRequest memory liqData = abi.decode(
            commonData.liqData,
            (LiqRequest)
        );

        uint256 loopLength = commonData.superFormIds.length;
        uint256 expAmount = _addValues(commonData.amounts);

        /// note: checking balance
        (address[] memory vaults, , ) = superFormFactory.getSuperForms(
            commonData.superFormIds
        );

        address collateral = address(ERC4626(vaults[0]).asset());
        uint256 balanceBefore = ERC20(collateral).balanceOf(address(this));

        /// note: handle the collateral token transfers.
        if (liqData.txData.length == 0) {
            require(
                ERC20(liqData.token).allowance(
                    commonData.srcSender,
                    address(this)
                ) >= liqData.amount,
                "Destination: Insufficient Allowance"
            );
            ERC20(liqData.token).safeTransferFrom(
                commonData.srcSender,
                address(this),
                liqData.amount
            );
        } else {
            dispatchTokens(
                bridgeAddress[liqData.bridgeId],
                liqData.txData,
                liqData.token,
                liqData.allowanceTarget,
                liqData.amount,
                commonData.srcSender,
                liqData.nativeAmount
            );
        }

        uint256 balanceAfter = ERC20(collateral).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore >= expAmount,
            "Destination: Invalid State & Liq Data"
        );

        dstAmounts = new uint256[](loopLength);

        for (uint256 i = 0; i < loopLength; i++) {
            ERC4626 v = ERC4626(vaults[i]);
            require(
                address(v.asset()) == collateral,
                "Destination: Invalid Collateral"
            );
            dstAmounts[i] = v.deposit(commonData.amounts[i], address(this));
        }
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        bytes calldata formData
    ) internal virtual override returns (uint256[] memory dstAmounts) {
        FormData memory data = abi.decode(formData, (FormData));

        FormCommonData memory commonData = abi.decode(
            data.commonData,
            (FormCommonData)
        );

        LiqRequest memory liqData = abi.decode(
            commonData.liqData,
            (LiqRequest)
        );

        uint256 len1 = liqData.txData.length;
        address receiver = len1 == 0
            ? address(commonData.srcSender)
            : address(this);

        uint256 loopLength = commonData.superFormIds.length;
        dstAmounts = new uint256[](loopLength);

        (address[] memory vaults, , ) = superFormFactory.getSuperForms(
            commonData.superFormIds
        );

        address collateral = address(ERC4626(vaults[0]).asset());

        for (uint256 i = 0; i < loopLength; i++) {
            ERC4626 v = ERC4626(vaults[i]);
            require(
                address(v.asset()) == collateral,
                "Destination: Invalid Collateral"
            );
            dstAmounts[i] = v.redeem(
                commonData.amounts[i],
                receiver,
                address(this)
            );
        }

        if (len1 != 0) {
            require(
                liqData.amount <= _addValues(dstAmounts),
                "Destination: Invalid Liq Request"
            );

            dispatchTokens(
                bridgeAddress[liqData.bridgeId],
                liqData.txData,
                liqData.token,
                liqData.allowanceTarget,
                liqData.amount,
                address(this),
                liqData.nativeAmount
            );
        }
    }

    function _xChainDepositIntoVault(
        XChainActionArgs memory args_
    ) internal virtual override {
        /// @dev TODO: Fix remove loops!!!!! See TokenBank.sol

        FormCommonData memory commonData = abi.decode(
            args_.commonData,
            (FormCommonData)
        );

        FormXChainData memory xChainData = abi.decode(
            args_.xChainData,
            (FormXChainData)
        );

        /// @dev Ordering dependency vaultIds need to match dstAmounts (shadow matched to user)

        uint256 len = commonData.superFormIds.length;
        (address[] memory vaults, , ) = superFormFactory.getSuperForms(
            commonData.superFormIds
        );

        uint256[] memory dstAmounts = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            ERC4626 v = ERC4626(vaults[i]);

            dstAmounts[i] = v.deposit(commonData.amounts[i], address(this));
            /// @notice dstAmounts is equal to POSITIONS returned by v(ault)'s deposit while data.amounts is equal to ASSETS (tokens) bridged
            emit Processed(
                args_.srcChainId,
                args_.dstChainId,
                xChainData.txId,
                commonData.amounts[i],
                vaults[i]
            );
        }

        /// Note Step-4: Send Data to Source to issue superform positions.
        stateRegistry.dispatchPayload{value: msg.value}(
            1, /// @dev come to this later to accept any bridge id
            args_.srcChainId,
            abi.encode(
                StateData(
                    TransactionType.DEPOSIT,
                    CallbackType.RETURN,
                    abi.encode(
                        ReturnData(
                            true,
                            args_.srcChainId,
                            chainId,
                            xChainData.txId,
                            dstAmounts
                        )
                    )
                )
            ),
            safeGasParam
        );
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        XChainActionArgs memory args_
    ) internal virtual override {
        /// @dev TODO: Fix remove loops!!!!! See TokenBank.sol

        FormCommonData memory commonData = abi.decode(
            args_.commonData,
            (FormCommonData)
        );

        LiqRequest memory liqData = abi.decode(
            commonData.liqData,
            (LiqRequest)
        );

        FormXChainData memory xChainData = abi.decode(
            args_.xChainData,
            (FormXChainData)
        );

        uint256 len = commonData.superFormIds.length;

        (address[] memory vaults, , ) = superFormFactory.getSuperForms(
            commonData.superFormIds
        );
        uint256[] memory dstAmounts = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            ERC4626 v = ERC4626(vaults[i]);
            if (liqData.txData.length != 0) {
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmounts[i] = v.redeem(
                    commonData.amounts[i],
                    address(this),
                    address(this)
                );

                uint256 balanceBefore = ERC20(v.asset()).balanceOf(
                    address(this)
                );
                /// Note Send Tokens to Source Chain
                /// FEAT Note: We could also allow to pass additional chainId arg here
                /// FEAT Note: Requires multiple ILayerZeroEndpoints to be mapped
                dispatchTokens(
                    bridgeAddress[liqData.bridgeId],
                    liqData.txData,
                    liqData.token,
                    liqData.allowanceTarget,
                    dstAmounts[i],
                    address(this),
                    liqData.nativeAmount
                );
                uint256 balanceAfter = ERC20(v.asset()).balanceOf(
                    address(this)
                );

                /// note: balance validation to prevent draining contract.
                require(
                    balanceAfter >= balanceBefore - dstAmounts[i],
                    "Destination: Invalid Liq Request"
                );
            } else {
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmounts[i] = v.redeem(
                    commonData.amounts[i],
                    address(commonData.srcSender),
                    address(this)
                );
            }

            emit Processed(
                args_.srcChainId,
                args_.dstChainId,
                xChainData.txId,
                dstAmounts[i],
                vaults[i]
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                INTERNAL VIEW VIRTUAL FUNCTIONS OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmount(
        address vault_,
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return ERC4626(vault_).convertToAssets(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        address vault_,
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return ERC4626(vault_).previewMint(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _underlyingAmountToVaultSharesAmount(
        address vault_,
        uint256 underlyingAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return ERC4626(vault_).convertToShares(underlyingAmount_);
    }

    /*///////////////////////////////////////////////////////////////
                            UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the sum of an array.
    /// @param amounts_ represents an array of inputs.
    function _addValues(
        uint256[] memory amounts_
    ) internal pure returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < amounts_.length; i++) {
            total += amounts_[i];
        }
        return total;
    }
}
