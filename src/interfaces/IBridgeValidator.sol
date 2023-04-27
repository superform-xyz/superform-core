// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {MultiVaultsSFData, SingleVaultSFData} from "../types/DataTypes.sol";

/// @title Bridge Handler Interface
/// @author Zeropoint Labs
interface IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev validates the amounts being sent in liqRequests
    /// @param superFormsData_ the multiVaults struct for the deposit
    function validateTxDataDepositMultiVaultAmounts(
        MultiVaultsSFData calldata superFormsData_
    ) external view returns (bool);

    /// @dev validates the amounts being sent in liqRequests
    /// @param superFormData_ the singleVault struct for the deposit
    function validateTxDataDepositSingleVaultAmount(
        SingleVaultSFData calldata superFormData_
    ) external view returns (bool);

    /// @dev validates the txData of a cross chain deposit
    /// @param txData_ the txData of the cross chain deposit
    /// @param srcChainId_ the chainId of the source chain
    /// @param dstChainId_ the chainId of the destination chain
    /// @param deposit_ true if the action is a deposit, false if it is a withdraw
    /// @param superForm_ the address of the superForm
    /// @param srcSender_ the address of the sender on the source chain
    /// @param liqDataToken_ the address of the liqDataToken
    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view;
}
