// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @dev is modified and imported from https://etherscan.io/address/0x111111125421ca6dc452d289314280a0f8842a65#code

type Address is uint256;

library AddressLib {
    uint256 private constant _LOW_160_BIT_MASK = (1 << 160) - 1;

    /**
     * @notice Returns the address representation of a uint256.
     * @param a The uint256 value to convert to an address.
     * @return The address representation of the provided uint256 value.
     */
    function get(Address a) internal pure returns (address) {
        return address(uint160(Address.unwrap(a) & _LOW_160_BIT_MASK));
    }

    /**
     * @notice Checks if a given flag is set for the provided address.
     * @param a The address to check for the flag.
     * @param flag The flag to check for in the provided address.
     * @return True if the provided flag is set in the address, false otherwise.
     */
    function getFlag(Address a, uint256 flag) internal pure returns (bool) {
        return (Address.unwrap(a) & flag) != 0;
    }

    /**
     * @notice Returns a uint32 value stored at a specific bit offset in the provided address.
     * @param a The address containing the uint32 value.
     * @param offset The bit offset at which the uint32 value is stored.
     * @return The uint32 value stored in the address at the specified bit offset.
     */
    function getUint32(Address a, uint256 offset) internal pure returns (uint32) {
        return uint32(Address.unwrap(a) >> offset);
    }

    /**
     * @notice Returns a uint64 value stored at a specific bit offset in the provided address.
     * @param a The address containing the uint64 value.
     * @param offset The bit offset at which the uint64 value is stored.
     * @return The uint64 value stored in the address at the specified bit offset.
     */
    function getUint64(Address a, uint256 offset) internal pure returns (uint64) {
        return uint64(Address.unwrap(a) >> offset);
    }
}

library ProtocolLib {
    using AddressLib for Address;

    enum Protocol {
        UniswapV2,
        UniswapV3,
        Curve
    }

    uint256 private constant _PROTOCOL_OFFSET = 253;
    uint256 private constant _WETH_UNWRAP_FLAG = 1 << 252;
    uint256 private constant _WETH_NOT_WRAP_FLAG = 1 << 251;
    uint256 private constant _USE_PERMIT2_FLAG = 1 << 250;

    function protocol(Address self) internal pure returns (Protocol) {
        // there is no need to mask because protocol is stored in the highest 3 bits
        return Protocol((Address.unwrap(self) >> _PROTOCOL_OFFSET));
    }

    function shouldUnwrapWeth(Address self) internal pure returns (bool) {
        return self.getFlag(_WETH_UNWRAP_FLAG);
    }

    function shouldWrapWeth(Address self) internal pure returns (bool) {
        return !self.getFlag(_WETH_NOT_WRAP_FLAG);
    }

    function usePermit2(Address self) internal pure returns (bool) {
        return self.getFlag(_USE_PERMIT2_FLAG);
    }

    function addressForPreTransfer(Address self) internal view returns (address) {
        if (protocol(self) == Protocol.UniswapV2) {
            return self.get();
        }
        return address(this);
    }
}

/// @dev imported from https://docs.uniswap.org/contracts/v2/reference/smart-contracts/pair#token1
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IAggregationRouterV6 {
    /**
     * @notice Swaps `amount` of the specified `token` for another token using an Unoswap-compatible exchange's pool,
     *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
     * @param to The address to receive the swapped tokens.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap.
     */
    function unoswapTo(
        Address to,
        Address token,
        uint256 amount,
        uint256 minReturn,
        Address dex
    )
        external
        returns (uint256 returnAmount);
}
