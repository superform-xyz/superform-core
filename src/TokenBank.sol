///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {TransactionType, CallbackType, AMBMessage, InitSingleVaultData, InitMultiVaultData, ReturnMultiData, ReturnSingleData} from "./types/DataTypes.sol";
import {IStateRegistry} from "./interfaces/IStateRegistry.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {ITokenBank} from "./interfaces/ITokenBank.sol";
import "./utils/DataPacking.sol";

/// @title Token Bank
/// @author Zeropoint Labs.
/// @dev Temporary area for underlying tokens to wait until they are ready to be sent to the form vault
contract TokenBank is ITokenBank, AccessControl {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant STATE_REGISTRY_ROLE =
        keccak256("STATE_REGISTRY_ROLE");

    /*///////////////////////////////////////////////////////////////
                     State Variables
    //////////////////////////////////////////////////////////////*/

    /// @dev safeGasParam is used while sending layerzero message from destination to router.
    bytes public safeGasParam;

    /// @notice state variable are all declared public to avoid creating functions to expose.

    /// @dev stateRegistry points to the state registry interface deployed in the respective chain.
    IStateRegistry stateRegistry;

    /// @dev chainId represents the superform chain id of the specific chain.
    uint16 public chainId;

    /// @dev superFormFactory address is used to query for forms based on Id received in the state sync data.
    ISuperFormFactory public superFormFactory;

    /// TODO: add bridge id to bridge address mapping
    /// @notice deploy stateRegistry before SuperDestination
    /// @param chainId_              Superform chain id
    /// @param stateRegistry_         State Registry address deployed
    /// @param superFormFactory_     SuperFormFactory address deployed
    /// @dev sets caller as the admin of the contract.
    /// @dev FIXME: missing means for admin to change implementations
    constructor(
        uint16 chainId_,
        IStateRegistry stateRegistry_,
        ISuperFormFactory superFormFactory_
    ) {
        chainId = chainId_;
        stateRegistry = stateRegistry_;
        superFormFactory = superFormFactory_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(STATE_REGISTRY_ROLE, address(stateRegistry_));
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev handles the state when received from the source chain.
    /// @param multiVaultData_     represents the struct with the associated multi vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositMultiSync(
        InitMultiVaultData memory multiVaultData_
    ) external payable override onlyRole(STATE_REGISTRY_ROLE) {
        (address[] memory vaults, uint256[] memory formIds, ) = _getSuperForms(
            multiVaultData_.superFormIds
        );
        address form;
        ERC20 underlying;
        uint256[] memory dstAmounts = new uint256[](
            multiVaultData_.superFormIds.length
        );

        for (uint256 i = 0; i < multiVaultData_.superFormIds.length; i++) {
            /// @dev FIXME: whole msg.value is transferred here, in multi sync this needs to be split

            form = superFormFactory.getForm(formIds[i]);
            underlying = IBaseForm(form).getUnderlyingOfVault(vaults[i]);

            /// @dev This will revert ALL of the transactions if one of them fails.
            if (
                underlying.balanceOf(address(this)) >=
                multiVaultData_.amounts[i]
            ) {
                underlying.transfer(form, multiVaultData_.amounts[i]);
                dstAmounts[i] = IBaseForm(form).xChainDepositIntoVault(
                    InitSingleVaultData({
                        txData: multiVaultData_.txData,
                        superFormId: multiVaultData_.superFormIds[i],
                        amount: multiVaultData_.amounts[i],
                        maxSlippage: multiVaultData_.maxSlippage[i],
                        extraFormData: multiVaultData_.extraFormData,
                        liqData: multiVaultData_.liqData
                    })
                );
            } else {
                revert BRIDGE_TOKENS_PENDING();
            }
        }

        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            multiVaultData_.txData
        );

        /// @notice Send Data to Source to issue superform positions.
        stateRegistry.dispatchPayload{value: msg.value}(
            1, /// @dev come to this later to accept any bridge id
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.DEPOSIT),
                        uint120(CallbackType.RETURN),
                        true
                    ),
                    abi.encode(
                        ReturnMultiData(
                            _packReturnTxInfo(
                                true,
                                srcChainId,
                                chainId,
                                currentTotalTxs
                            ),
                            dstAmounts
                        )
                    )
                )
            ),
            safeGasParam
        );
    }

    /// @dev handles the state when received from the source chain.
    /// @param singleVaultData_       represents the struct with the associated single vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositSync(
        InitSingleVaultData memory singleVaultData_
    ) external payable override onlyRole(STATE_REGISTRY_ROLE) {
        (address vault_, uint256 formId_, ) = _getSuperForm(
            singleVaultData_.superFormId
        );
        address form = superFormFactory.getForm(formId_);
        ERC20 underlying = IBaseForm(form).getUnderlyingOfVault(vault_);
        uint256 dstAmount;
        /// @dev This will revert ALL of the transactions if one of them fails.
        
        /// DEVNOTE: This will revert with an error only descriptive of the first possible revert out of many
        /// 1. Not enough tokens on this contract == BRIDGE_TOKENS_PENDING
        /// 2. Fail to .transfer() == BRIDGE_TOKENS_PENDING
        /// 3. xChainDepositIntoVault() reverting on anything == BRIDGE_TOKENS_PENDING
        /// FIXME: Add reverts at the Form level
        if (underlying.balanceOf(address(this)) >= singleVaultData_.amount) {
            underlying.transfer(form, singleVaultData_.amount);

            dstAmount = IBaseForm(form).xChainDepositIntoVault(
                singleVaultData_
            );
        } else {
            revert BRIDGE_TOKENS_PENDING();
        }

        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            singleVaultData_.txData
        );

        /// @notice Send Data to Source to issue superform positions.
        stateRegistry.dispatchPayload{value: msg.value}(
            1, /// @dev come to this later to accept any bridge id
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.DEPOSIT),
                        uint120(CallbackType.RETURN),
                        true
                    ),
                    abi.encode(
                        ReturnSingleData(
                            _packReturnTxInfo(
                                true,
                                srcChainId,
                                chainId,
                                currentTotalTxs
                            ),
                            dstAmount
                        )
                    )
                )
            ),
            safeGasParam
        );
    }

    /// @dev handles the state when received from the source chain.
    /// @param multiVaultData_       represents the struct with the associated multi vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function withdrawMultiSync(
        InitMultiVaultData memory multiVaultData_
    ) external payable override onlyRole(STATE_REGISTRY_ROLE) {
        /// @dev This will revert ALL of the transactions if one of them fails.
        for (uint256 i = 0; i < multiVaultData_.superFormIds.length; i++) {
            withdrawSync(
                InitSingleVaultData({
                    txData: multiVaultData_.txData,
                    superFormId: multiVaultData_.superFormIds[i],
                    amount: multiVaultData_.amounts[i],
                    maxSlippage: multiVaultData_.maxSlippage[i],
                    extraFormData: multiVaultData_.extraFormData,
                    liqData: multiVaultData_.liqData
                })
            );
        }
    }

    /// @dev handles the state when received from the source chain.
    /// @param singleVaultData_       represents the struct with the associated single vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function withdrawSync(
        InitSingleVaultData memory singleVaultData_
    ) public payable override onlyRole(STATE_REGISTRY_ROLE) {
        (, uint256 formId_, ) = _getSuperForm(singleVaultData_.superFormId);

        IBaseForm(superFormFactory.getForm(formId_)).xChainWithdrawFromVault(
            singleVaultData_
        );
    }

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev adds the gas overrides for layerzero.
    /// @param param_    represents adapterParams V2.0 of layerzero
    function updateSafeGasParam(
        bytes memory param_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (param_.length == 0) revert INVALID_GAS_OVERRIDE();
        bytes memory oldParam = safeGasParam;
        safeGasParam = param_;

        emit SafeGasParamUpdated(oldParam, param_);
    }
}
