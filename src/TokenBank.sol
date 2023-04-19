///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {TransactionType, CallbackType, AMBMessage, InitSingleVaultData, InitMultiVaultData, ReturnMultiData, ReturnSingleData, AckExtraData} from "./types/DataTypes.sol";
import {LiqRequest} from "./types/DataTypes.sol";
import {IBaseStateRegistry} from "./interfaces/IBaseStateRegistry.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ITokenBank} from "./interfaces/ITokenBank.sol";
import {Error} from "./utils/Error.sol";
import "./utils/DataPacking.sol";

/// @title Token Bank
/// @author Zeropoint Labs.
/// @dev Temporary area for underlying tokens to wait until they are ready to be sent to the form vault
contract TokenBank is ITokenBank {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant STATE_REGISTRY_ROLE =
        keccak256("STATE_REGISTRY_ROLE");

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/

    /// @dev superRegistry points to the super registry deployed in the respective chain.
    ISuperRegistry public immutable superRegistry;

    /// @dev chainId represents the superform chain id of the specific chain.
    uint16 public immutable chainId;

    modifier onlyStateRegistry() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasCoreStateRegistryRole(
                msg.sender
            )
        ) revert Error.NOT_CORE_STATE_REGISTRY();
        _;
    }

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /// @param chainId_              Superform chain id
    /// @param superRegistry_ the superform registry contract
    constructor(uint16 chainId_, address superRegistry_) {
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        superRegistry = ISuperRegistry(superRegistry_);
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
        InitMultiVaultData memory multiVaultData_,
        bytes memory ackExtraData_
    ) external payable override onlyStateRegistry {
        (address[] memory superForms, , ) = _getSuperForms(
            multiVaultData_.superFormIds
        );
        ERC20 underlying;
        uint256[] memory dstAmounts = new uint256[](
            multiVaultData_.superFormIds.length
        );

        for (uint256 i = 0; i < multiVaultData_.superFormIds.length; i++) {
            /// @dev FIXME: whole msg.value is transferred here, in multi sync this needs to be split

            underlying = IBaseForm(superForms[i]).getUnderlyingOfVault();

            /// @dev This will revert ALL of the transactions if one of them fails.
            if (
                underlying.balanceOf(address(this)) >=
                multiVaultData_.amounts[i]
            ) {
                underlying.transfer(superForms[i], multiVaultData_.amounts[i]);
                LiqRequest memory emptyRequest;

                dstAmounts[i] = IBaseForm(superForms[i]).xChainDepositIntoVault(
                    InitSingleVaultData({
                        txData: multiVaultData_.txData,
                        superFormId: multiVaultData_.superFormIds[i],
                        amount: multiVaultData_.amounts[i],
                        maxSlippage: multiVaultData_.maxSlippage[i],
                        liqData: emptyRequest,
                        extraFormData: multiVaultData_.extraFormData
                    })
                );
            } else {
                revert Error.BRIDGE_TOKENS_PENDING();
            }
        }

        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            multiVaultData_.txData
        );

        AckExtraData memory ackData = abi.decode(ackExtraData_, (AckExtraData));

        /// @notice Send Data to Source to issue superform positions.
        IBaseStateRegistry(superRegistry.coreStateRegistry()).dispatchPayload{
            value: msg.value
        }(
            ackData.ambIds,
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.DEPOSIT),
                        uint120(CallbackType.RETURN),
                        true,
                        0
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
            ackData.ambOverride
        );
    }

    /// @dev handles the state when received from the source chain.
    /// @param singleVaultData_       represents the struct with the associated single vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositSync(
        InitSingleVaultData memory singleVaultData_,
        bytes memory ackExtraData_
    ) external payable override onlyStateRegistry {
        (address superForm_, , ) = _getSuperForm(singleVaultData_.superFormId);

        ERC20 underlying = IBaseForm(superForm_).getUnderlyingOfVault();
        uint256 dstAmount;
        /// @dev This will revert ALL of the transactions if one of them fails.

        /// DEVNOTE: This will revert with an error only descriptive of the first possible revert out of many
        /// 1. Not enough tokens on this contract == BRIDGE_TOKENS_PENDING
        /// 2. Fail to .transfer() == BRIDGE_TOKENS_PENDING
        /// 3. xChainDepositIntoVault() reverting on anything == BRIDGE_TOKENS_PENDING
        /// FIXME: Add reverts at the Form level
        if (underlying.balanceOf(address(this)) >= singleVaultData_.amount) {
            underlying.transfer(superForm_, singleVaultData_.amount);

            dstAmount = IBaseForm(superForm_).xChainDepositIntoVault(
                singleVaultData_
            );
        } else {
            revert Error.BRIDGE_TOKENS_PENDING();
        }

        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            singleVaultData_.txData
        );

        AckExtraData memory ackData = abi.decode(ackExtraData_, (AckExtraData));

        /// @notice Send Data to Source to issue superform positions.
        IBaseStateRegistry(superRegistry.coreStateRegistry()).dispatchPayload{
            value: msg.value
        }(
            ackData.ambIds,
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.DEPOSIT),
                        uint120(CallbackType.RETURN),
                        false,
                        0
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
            ackData.ambOverride
        );
    }

    /// @dev handles the state when received from the source chain.
    /// @param multiVaultData_       represents the struct with the associated multi vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function withdrawMultiSync(
        InitMultiVaultData memory multiVaultData_
    ) external payable override onlyStateRegistry {
        /// @dev This will revert ALL of the transactions if one of them fails.
        for (uint256 i = 0; i < multiVaultData_.superFormIds.length; i++) {
            withdrawSync(
                InitSingleVaultData({
                    txData: multiVaultData_.txData,
                    superFormId: multiVaultData_.superFormIds[i],
                    amount: multiVaultData_.amounts[i],
                    maxSlippage: multiVaultData_.maxSlippage[i],
                    liqData: multiVaultData_.liqData[i],
                    extraFormData: multiVaultData_.extraFormData
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
    ) public payable override onlyStateRegistry {
        (address superForm_, , ) = _getSuperForm(singleVaultData_.superFormId);

        IBaseForm(superForm_).xChainWithdrawFromVault(singleVaultData_);
    }
}
