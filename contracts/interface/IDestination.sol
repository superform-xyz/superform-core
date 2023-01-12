// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.14;

import {LiqRequest} from "../types/socketTypes.sol";

interface IDestination {
    function directDeposit(
        address srcSender,
        LiqRequest memory liqData,
        uint256[] memory vaultIds,
        uint256[] memory amounts
    ) external payable returns (uint256[] memory dstAmounts);

    function directWithdraw(
        address srcSender,
        uint256[] memory vaultIds,
        uint256[] memory amounts,
        LiqRequest memory _liqData
    ) external payable;

    function stateSync(bytes memory _payload) external payable;

    function safeGasParam() external view returns (bytes memory);
}
