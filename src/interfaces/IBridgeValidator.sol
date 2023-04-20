// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title Bridge Handler Interface
/// @author Zeropoint Labs
interface IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_
    ) external view returns (bool);
}
