// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IStateRegistry} from "../interfaces/IStateRegistry.sol";
import {IAmbImplementation} from "../interfaces/IAmbImplementation.sol";
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ITokenBank} from "../interfaces/ITokenBank.sol";
import {StateData, PayloadState, TransactionType, CallbackType, ReturnData, FormData, FormCommonData, FormXChainData} from "../types/DataTypes.sol";

import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "../interfaces/IBaseForm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import "forge-std/console.sol";

/// @title Cross-Chain AMB Aggregator
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
contract StateRegistry is IStateRegistry, AccessControl {

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /*///////////////////////////////////////////////////////////////
                    ACCESS CONTROL ROLE CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant IMPLEMENTATION_CONTRACTS_ROLE =
        keccak256("IMPLEMENTATION_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev superformChainid
    uint80 public immutable chainId;
    uint256 public payloadsCount;

    address public routerContract;

    /// NOTE: Shouldnt we use multiple tokenBanks to benefit from using them?
    ITokenBank public tokenBankContract;

    ISuperFormFactory public superFormFactory;

    mapping(uint8 => IAmbImplementation) public amb;

    /// @dev stores all received payloads after assigning them an unique identifier upon receiving.
    mapping(uint256 => bytes) public payload;

    /// @dev maps payloads to their status
    mapping(uint256 => PayloadState) public payloadTracking;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    ///@dev set up admin during deployment.
    constructor(uint80 chainId_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        chainId = chainId_;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev allows admin to update amb implementations.
    /// @param ambId_ is the propreitory amb id.
    /// @param ambImplementation_ is the implementation address.
    function configureAmb(
        uint8 ambId_,
        address ambImplementation_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (ambId_ == 0) {
            revert INVALID_BRIDGE_ID();
        }

        if (ambImplementation_ == address(0)) {
            revert INVALID_BRIDGE_ADDRESS();
        }

        amb[ambId_] = IAmbImplementation(ambImplementation_);
        emit AmbConfigured(ambId_, ambImplementation_);
    }

    /// @dev allows accounts with {DEFAULT_ADMIN_ROLE} to update the core contracts
    /// @param routerContract_ is the address of the router`
    /// @param tokenBankContract_ is the address of the token bank
    function setCoreContracts(
        address routerContract_,
        address tokenBankContract_,
        address superFormFactory_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        routerContract = routerContract_;
        tokenBankContract = ITokenBank(tokenBankContract_);
        superFormFactory = ISuperFormFactory(superFormFactory_);
        emit CoreContractsUpdated(routerContract_, tokenBankContract_);
    }

    /// @dev allows core contracts to send data to a destination chain.
    /// @param ambId_ is the identifier of the message amb to be used.
    /// @param dstChainId_ is the internal chainId used throughtout the protocol.
    /// @param message_ is the crosschain data to be sent.
    /// @param extraData_ defines all the message amb specific information.
    /// NOTE: dstChainId maps with the message amb's propreitory chain Id.
    function dispatchPayload(
        uint8 ambId_,
        uint80 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyRole(CORE_CONTRACTS_ROLE) {
        IAmbImplementation ambImplementation = amb[ambId_];

        if (address(ambImplementation) == address(0)) {
            revert INVALID_BRIDGE_ID();
        }

        ambImplementation.dipatchPayload{value: msg.value}(
            dstChainId_,
            message_,
            extraData_
        );
    }

    /// @dev allows state registry to receive messages from amb implementations.
    /// @param srcChainId_ is the internal chainId from which the data is sent.
    /// @param message_ is the crosschain data received.
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(
        uint80 srcChainId_,
        bytes memory message_
    ) external virtual override onlyRole(IMPLEMENTATION_CONTRACTS_ROLE) {
        ++payloadsCount;
        payload[payloadsCount] = message_;

        emit PayloadReceived(srcChainId_, chainId, payloadsCount);
    }

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updatePayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    ) external virtual override onlyRole(UPDATER_ROLE) {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        StateData memory payloadInfo = abi.decode(
            payload[payloadId_],
            (StateData)
        );

        if (
            payloadInfo.txType != TransactionType.DEPOSIT &&
            payloadInfo.flag != CallbackType.INIT
        ) {
            revert INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (payloadTracking[payloadId_] != PayloadState.STORED) {
            revert INVALID_PAYLOAD_STATE();
        }

        FormData memory formData = abi.decode(payloadInfo.params, (FormData));
        FormCommonData memory formCommonData = abi.decode(
            formData.commonData,
            (FormCommonData)
        );
        FormXChainData memory formXChainData = abi.decode(
            formData.xChainData,
            (FormXChainData)
        );

        uint256 l1 = formCommonData.amounts.length;
        uint256 l2 = finalAmounts_.length;

        if (l1 != l2) {
            revert INVALID_ARR_LENGTH();
        }

        for (uint256 i = 0; i < l1; i++) {
            uint256 newAmount = finalAmounts_[i]; /// backend fed amounts of socket tokens expected
            uint256 maxAmount = formCommonData.amounts[i];

            if (newAmount > maxAmount) {
                revert NEGATIVE_SLIPPAGE();
            }

            uint256 minAmount = (maxAmount *
                (10000 - formXChainData.maxSlippage[i])) / 10000;

            if (newAmount < minAmount) {
                revert SLIPPAGE_OUT_OF_BOUNDS();
            }
        }

        formCommonData.amounts = finalAmounts_;

        FormData memory updatedFormData = FormData(
            formData.srcChainId,
            formData.dstChainId,
            abi.encode(formCommonData),
            formData.xChainData,
            formData.extraFormData
        );

        payloadInfo.params = abi.encode(updatedFormData);

        payload[payloadId_] = abi.encode(payloadInfo);
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_
    ) external payable virtual override onlyRole(PROCESSOR_ROLE) {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert INVALID_PAYLOAD_STATE();
        }

        bytes memory _payload = payload[payloadId_];
        StateData memory payloadInfo = abi.decode(_payload, (StateData));

        FormData memory data = abi.decode(payloadInfo.params, (FormData));
        FormCommonData memory commonData = abi.decode(
            data.commonData,
            (FormCommonData)
        );

        for (uint256 i = 0; i < commonData.superFormIds.length; i++) {
            (address vault_, uint256 formId_, ) = superFormFactory.getSuperForm(
                commonData.superFormIds[i]
            );

            address form = superFormFactory.getForm(formId_);

            if (payloadInfo.txType == TransactionType.DEPOSIT) {
                if (payloadInfo.flag == CallbackType.INIT) {
                    if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                        revert PAYLOAD_NOT_UPDATED();
                    }
                    payloadTracking[payloadId_] = PayloadState.PROCESSED;
                    
                    console.log("tokenBank");
                    tokenBankContract.stateSync{value: msg.value}(
                            _payload
                        );

                } else {
                    if (payloadTracking[payloadId_] != PayloadState.STORED) {
                        revert INVALID_PAYLOAD_STATE();
                    }
                    payloadTracking[payloadId_] = PayloadState.PROCESSED;

                    ISuperRouter(routerContract).stateSync{value: msg.value}(
                        abi.encode(payloadInfo)
                    );
                }
            } else {
                payloadTracking[payloadId_] = PayloadState.PROCESSED;

                if (payloadInfo.flag == CallbackType.INIT) {
                    tokenBankContract.stateSync(
                            _payload
                        );
                } else {
                    ISuperRouter(routerContract).stateSync{value: msg.value}(
                        abi.encode(payloadInfo)
                    );
                }
            }
        }
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert payload that fail to revert state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param ambId_ is the identifier of the cross-chain amb to be used to send the acknowledgement.
    /// @param extraData_ is any message amb specific override information.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256 ambId_,
        bytes memory extraData_
    ) external payable virtual override onlyRole(PROCESSOR_ROLE) {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert INVALID_PAYLOAD_STATE();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        StateData memory payloadInfo = abi.decode(
            payload[payloadId_],
            (StateData)
        );
        FormData memory formData = abi.decode(payloadInfo.params, (FormData));

        if (formData.dstChainId != chainId) {
            revert INVALID_PAYLOAD_STATE();
        }

        /// NOTE: Send `data` back to source based on AmbID to revert the state.
        /// NOTE: chain_ids conflict should be addresses here.
        // amb[ambId_].dipatchPayload(formData.dstChainId_, message_, extraData_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // function _processWithdrawal(
    //     uint256 payloadId_,
    //     StateData memory payloadInfo_
    // ) internal {
    //     payloadTracking[payloadId_] = PayloadState.PROCESSED;

    //     if (payloadInfo_.flag == CallbackType.INIT) {
    //         ITokenBank(tokenBankContract).stateSync{value: msg.value}(
    //             abi.encode(payloadInfo_)
    //         );
    //     } else {
    //         ISuperRouter(routerContract).stateSync{value: msg.value}(
    //             abi.encode(payloadInfo_)
    //         );
    //     }
    // }

    // function _processDeposit(
    //     uint256 payloadId_,
    //     StateData memory payloadInfo_
    // ) internal {
    //     if (payloadInfo_.flag == CallbackType.INIT) {
    //         if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
    //             revert PAYLOAD_NOT_UPDATED();
    //         }
    //         payloadTracking[payloadId_] = PayloadState.PROCESSED;

    //         ITokenBank(tokenBankContract).stateSync{value: msg.value}(
    //             abi.encode(payloadInfo_)
    //         );
    //     } else {
    //         if (payloadTracking[payloadId_] != PayloadState.STORED) {
    //             revert INVALID_PAYLOAD_STATE();
    //         }
    //         payloadTracking[payloadId_] = PayloadState.PROCESSED;

    //         ISuperRouter(routerContract).stateSync{value: msg.value}(
    //             abi.encode(payloadInfo_)
    //         );
    //     }
    // }
}
