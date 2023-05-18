// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {IERC4626TimelockVault} from "../../forms/interfaces/IERC4626TimelockVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @notice Mock ERC4626Timelock contract
/// @dev Requires two separate calls to perform ERC4626.withdraw() or redeem()
/// @dev First call is to requestUnlock() and second call is to withdraw() or redeem()
/// @dev Allows canceling unlock request
/// @dev Designed to mimick behavior of timelock vaults covering most of the use cases abstracted
contract ERC4626TimelockMock is ERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    uint256 public lockPeriod = 100;
    uint256 public requestId;

    struct UnlockRequest {
        /// Unique id of the request
        uint id;
        // The timestamp at which the `shareAmount` was requested to be unlocked
        uint startedAt;
        // The amount of shares to burn
        uint shareAmount;
    }

    mapping(address owner => UnlockRequest) public requests;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC4626(asset_, name_, symbol_) {}

    function totalAssets() public view override returns (uint256) {
        /// @dev placeholder, we just use it for mock
        return asset.balanceOf(address(this));
    }

    function userUnlockRequests(
        address owner
    ) external view returns (UnlockRequest memory) {
        return requests[owner];
    }

    function getLockPeirod() external view returns (uint256) {
        return lockPeriod;
    }

    /// @notice Mock Timelock-like behavior (a need for two separate calls to withdraw)
    function requestUnlock(uint256 sharesAmount, address owner) external {
        require(requests[owner].shareAmount == 0, "ALREADY_REQUESTED");

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - sharesAmount;
        }

        /// @dev Burns shares. other impls may require to safeTransferFrom() to vault address
        _burn(owner, sharesAmount);

        /// @dev Internal tracking of withdraw/redeem requests routed through this vault
        requestId++;
        requests[owner] = (
            UnlockRequest({
                id: requestId,
                startedAt: block.timestamp,
                shareAmount: sharesAmount
            })
        );
    }

    function cancelUnlock(address owner) external {
        UnlockRequest storage request = requests[owner];
        require(
            request.startedAt + lockPeriod > block.timestamp,
            "NOT_UNLOCKED"
        );

        /// @dev Mint shares back
        /// NOTE: This method needs to be tested for re-basing shares
        _mint(owner, request.shareAmount);

        delete requests[owner];
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        /// @dev Mock Timelock-like behavior (a need for cooldown period to pass)
        /// @dev Mock Timelock-like behavior (enough of the shares unlocked)
        UnlockRequest storage request = requests[owner];
        require(
            request.startedAt + lockPeriod <= block.timestamp,
            "NOT_UNLOCKED"
        );
        require(request.shareAmount >= shares, "SHARES_LOCKED");

        if (request.shareAmount == shares) {
            delete requests[owner];
        } else {
            request.shareAmount -= shares;
        }

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        /// @dev Mock Timelock-like behavior (a need for cooldown period to pass)
        /// @dev Mock Timelock-like behavior (enough of the shares unlocked)
        UnlockRequest storage request = requests[owner];
        require(
            request.startedAt + lockPeriod <= block.timestamp,
            "NOT_UNLOCKED"
        );
        require(request.shareAmount >= shares, "SHARES_LOCKED");

        if (request.shareAmount == shares) {
            delete requests[owner];
        } else {
            request.shareAmount -= shares;
        }

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }
}
