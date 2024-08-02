// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @dev is modified and imported from https://etherscan.io/address/0x111111125421ca6dc452d289314280a0f8842a65#code

type Address is uint256;

uint256 constant _CURVE_TO_COINS_ARG_MASK = 0xff;
uint256 constant _CURVE_TO_COINS_ARG_OFFSET = 216;
uint256 constant _PARTIAL_FILL = 1 << 0;
uint256 constant _REQUIRES_EXTRA_ETH = 1 << 1;
uint256 constant _USE_PERMIT2 = 1 << 2;

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
interface IUniswapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ICurvePool {
    function underlying_coins(int128 index) external view returns (address);
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IClipperExchange {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function sellEthForToken(
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    )
        external
        payable;
    function sellTokenForEth(
        address inputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    )
        external;
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    )
        external;
}

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable returns (uint256); // 0x4b64e492
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

    function clipperSwapTo(
        IClipperExchange clipperExchange,
        address payable recipient,
        Address srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 expiryWithFlags,
        bytes32 r,
        bytes32 vs
    )
        external
        payable
        returns (uint256 returnAmount);

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(IAggregationExecutor executor, SwapDescription calldata desc, bytes calldata data) external payable;
}
