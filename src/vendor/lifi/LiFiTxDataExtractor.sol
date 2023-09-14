// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
/// @title LiFiTxDataExtractor
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for extracting calldata
/// @notice upgraded to solidity 0.8.19 and adapted from CalldataVerificationFacet and LibBytes without any changes to
/// used functions (just stripped down functionality and renamed contract name)
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts
/// @custom:version 1.1.0

contract LiFiTxDataExtractor {
    error SliceOverflow();
    error SliceOutOfBounds();

    /// @notice Extracts the bridge data from the calldata
    /// @param data The calldata to extract the bridge data from
    /// @return bridgeData The bridge data extracted from the calldata
    function _extractBridgeData(bytes calldata data) internal pure returns (ILiFi.BridgeData memory bridgeData) {
        if (abi.decode(data, (bytes4)) == 0xd6a4bc50) {
            // StandardizedCall
            bytes memory unwrappedData = abi.decode(data[4:], (bytes));
            bridgeData = abi.decode(slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData));
            return bridgeData;
        }
        // normal call
        bridgeData = abi.decode(data[4:], (ILiFi.BridgeData));
    }

    /// @notice Extracts the swap data from the calldata
    /// @param data The calldata to extract the swap data from
    /// @return swapData The swap data extracted from the calldata
    function _extractSwapData(bytes calldata data) internal pure returns (LibSwap.SwapData[] memory swapData) {
        if (abi.decode(data, (bytes4)) == 0xd6a4bc50) {
            // standardizedCall
            bytes memory unwrappedData = abi.decode(data[4:], (bytes));
            (, swapData) =
                abi.decode(slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData, LibSwap.SwapData[]));
            return swapData;
        }
        // normal call
        (, swapData) = abi.decode(data[4:], (ILiFi.BridgeData, LibSwap.SwapData[]));
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert SliceOverflow();
        if (_bytes.length < _start + _length) revert SliceOutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}
