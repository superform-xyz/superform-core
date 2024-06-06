// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";

/// @title IERC5115To4626Wrapper
/// @dev Interface forIERC5115To4626Wrapper
/// @author Zeropoint Labs
interface IERC5115To4626Wrapper is IStandardizedYield {
    function getUnderlying5115Vault() external view returns (address);

    function getMainTokenIn() external view returns (address);
}
