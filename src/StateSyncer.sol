///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { AMBMessage } from "./types/DataTypes.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { IStateSyncer } from "./interfaces/IStateSyncer.sol";

import { Error } from "./utils/Error.sol";

/// @title StateSyncer
/// @author Zeropoint Labs.
/// @dev base contract for stateSync functions
abstract contract StateSyncer is IStateSyncer {
    /*///////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the super registry address
    ISuperRegistry public immutable superRegistry;
    uint8 public immutable ROUTER_TYPE;

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => uint256 txInfo) public override txHistory;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyRouter() {
        if (superRegistry.getAddress(keccak256("SUPERFORM_ROUTER")) != msg.sender) revert Error.NOT_SUPER_ROUTER();
        _;
    }
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    /// @param routerType_ the router type
    constructor(address superRegistry_, uint8 routerType_) {
        superRegistry = ISuperRegistry(superRegistry_);
        ROUTER_TYPE = routerType_;
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStateSyncer
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external override onlyRouter {
        txHistory[payloadId_] = txInfo_;
    }

    /// @inheritdoc IStateSyncer
    function stateMultiSync(AMBMessage memory data_) external payable virtual override returns (uint64 srcChainId_);

    /// @inheritdoc IStateSyncer
    function stateSync(AMBMessage memory data_) external payable virtual override returns (uint64 srcChainId_);

    /// @inheritdoc IStateSyncer
    function stateSyncTwoStep(address sender_, uint256 superformid, uint256 amount) external payable virtual override;
}
