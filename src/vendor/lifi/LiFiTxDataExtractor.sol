// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { StandardizedCallFacet } from "./StandardizedCallFacet.sol";
import { AmarokFacet } from "./AmarokFacet.sol";
import { CBridgeFacetPacked } from "./CBridgeFacetPacked.sol";
import { HopFacetPacked } from "./HopFacetPacked.sol";
import { CelerIMFacetBase, CelerIM } from "./CelerIMFacetBase.sol";
import { StargateFacet } from "./StargateFacet.sol";

/// @title LiFiTxDataExtractor
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for extracting calldata
/// @notice upgraded to solidity 0.8.23 and adapted from CalldataVerificationFacet and LibBytes without any changes to
/// used functions (just stripped down functionality and renamed contract name)
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts
/// @custom:version 2.2.0
contract LiFiTxDataExtractor {
    error SliceOverflow();
    error SliceOutOfBounds();

    /// @dev this function blacklists certain packed and min selectors.
    /// @notice this is a patch to prevent a user to bypass our txData validation checks
    /// @notice the offered solution here is not scallable and should be replaced by a better solution with a lifi
    /// maintained list
    function _validateSelector(bytes4 selector) internal pure returns (bool valid) {
        if (selector == CBridgeFacetPacked.startBridgeTokensViaCBridgeNativePacked.selector) {
            return false;
        }
        if (selector == CBridgeFacetPacked.startBridgeTokensViaCBridgeNativeMin.selector) {
            return false;
        }
        if (selector == CBridgeFacetPacked.startBridgeTokensViaCBridgeERC20Packed.selector) {
            return false;
        }
        if (selector == CBridgeFacetPacked.startBridgeTokensViaCBridgeERC20Min.selector) {
            return false;
        }
        if (selector == HopFacetPacked.startBridgeTokensViaHopL2NativePacked.selector) {
            return false;
        }
        if (selector == HopFacetPacked.startBridgeTokensViaHopL2NativeMin.selector) {
            return false;
        }
        if (selector == HopFacetPacked.startBridgeTokensViaHopL2ERC20Packed.selector) {
            return false;
        }

        if (selector == HopFacetPacked.startBridgeTokensViaHopL2ERC20Min.selector) {
            return false;
        }

        if (selector == HopFacetPacked.startBridgeTokensViaHopL1NativePacked.selector) {
            return false;
        }

        if (selector == HopFacetPacked.startBridgeTokensViaHopL1NativeMin.selector) {
            return false;
        }

        if (selector == HopFacetPacked.startBridgeTokensViaHopL1ERC20Packed.selector) {
            return false;
        }

        if (selector == HopFacetPacked.startBridgeTokensViaHopL1ERC20Min.selector) {
            return false;
        }
        /// @dev prevent recursive calls
        if (selector == StandardizedCallFacet.standardizedCall.selector) {
            return false;
        }
        return true;
    }

    function _extractSelector(bytes calldata data) internal pure returns (bytes4 selector) {
        selector = bytes4(data[:4]);
        if (selector == StandardizedCallFacet.standardizedCall.selector) selector = bytes4(data[4:8]);
    }

    /// @notice Extracts the bridge data from the calldata. Extracts receiver correctly pending certain facet features
    /// @param data The calldata to extract the bridge data from
    /// @return bridgeData The bridge data extracted from the calldata
    function _extractBridgeData(bytes calldata data)
        internal
        pure
        returns (ILiFi.BridgeData memory bridgeData, address receiver)
    {
        bytes memory callData = data;

        if (bytes4(data[:4]) == StandardizedCallFacet.standardizedCall.selector) {
            // StandardizedCall
            callData = abi.decode(data[4:], (bytes));
        }

        bytes4 selector = abi.decode(callData, (bytes4));

        // Case: Amarok
        if (selector == AmarokFacet.startBridgeTokensViaAmarok.selector) {
            AmarokFacet.AmarokData memory amarokData;
            (bridgeData, amarokData) =
                abi.decode(_slice(callData, 4, callData.length - 4), (ILiFi.BridgeData, AmarokFacet.AmarokData));
            receiver = amarokData.callTo;

            return (bridgeData, receiver);
        }
        if (selector == AmarokFacet.swapAndStartBridgeTokensViaAmarok.selector) {
            AmarokFacet.AmarokData memory amarokData;

            (bridgeData,, amarokData) = abi.decode(
                _slice(callData, 4, callData.length - 4), (ILiFi.BridgeData, LibSwap.SwapData[], AmarokFacet.AmarokData)
            );
            receiver = amarokData.callTo;

            return (bridgeData, receiver);
        }

        // Case: Stargate
        if (selector == StargateFacet.startBridgeTokensViaStargate.selector) {
            StargateFacet.StargateData memory stargateData;
            (bridgeData, stargateData) =
                abi.decode(_slice(callData, 4, callData.length - 4), (ILiFi.BridgeData, StargateFacet.StargateData));

            bytes memory to = stargateData.callTo;
            assembly {
                receiver := mload(add(to, 20))
            }

            return (bridgeData, receiver);
        }
        if (selector == StargateFacet.swapAndStartBridgeTokensViaStargate.selector) {
            StargateFacet.StargateData memory stargateData;
            (bridgeData,, stargateData) = abi.decode(
                _slice(callData, 4, callData.length - 4),
                (ILiFi.BridgeData, LibSwap.SwapData[], StargateFacet.StargateData)
            );
            bytes memory to = stargateData.callTo;
            assembly {
                receiver := mload(add(to, 20))
            }
            return (bridgeData, receiver);
        }

        // Case: Celer
        if (selector == CelerIMFacetBase.startBridgeTokensViaCelerIM.selector) {
            CelerIM.CelerIMData memory celerIMData;
            (bridgeData, celerIMData) =
                abi.decode(_slice(callData, 4, callData.length - 4), (ILiFi.BridgeData, CelerIM.CelerIMData));

            receiver = bridgeData.receiver;

            return (bridgeData, receiver);
        }
        if (selector == CelerIMFacetBase.swapAndStartBridgeTokensViaCelerIM.selector) {
            CelerIM.CelerIMData memory celerIMData;

            (bridgeData,, celerIMData) = abi.decode(
                _slice(callData, 4, callData.length - 4), (ILiFi.BridgeData, LibSwap.SwapData[], CelerIM.CelerIMData)
            );
            receiver = bridgeData.receiver;

            return (bridgeData, receiver);
        }

        // normal call
        bridgeData = abi.decode(data[4:], (ILiFi.BridgeData));
        receiver = bridgeData.receiver;
    }

    /// @notice Extracts the swap data from the calldata
    /// @param data The calldata to extract the swap data from
    /// @return swapData The swap data extracted from the calldata
    function _extractSwapData(bytes calldata data) internal pure returns (LibSwap.SwapData[] memory swapData) {
        if (bytes4(data[:4]) == StandardizedCallFacet.standardizedCall.selector) {
            // standardizedCall
            bytes memory unwrappedData = abi.decode(data[4:], (bytes));
            (, swapData) =
                abi.decode(_slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData, LibSwap.SwapData[]));
            return swapData;
        }
        // normal call
        (, swapData) = abi.decode(data[4:], (ILiFi.BridgeData, LibSwap.SwapData[]));
    }

    function _slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
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
