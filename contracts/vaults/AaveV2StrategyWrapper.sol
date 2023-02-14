// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import {IMultiFeeDistribution} from "./utils/aave/IMultiFeeDistribution.sol";
import {ILendingPool} from "./utils/aave/ILendingPool.sol";
import {DexSwap} from "./utils/swapUtils.sol";

/// @title AaveV2StrategyWrapper - Custom implementation of yield-daddy wrappers with flexible reinvesting logic
/// Rationale: Forked protocols often implement custom functions and modules on top of forked code.
/// Example: Aave-forked protocol doesn't use AaveMining for rewards distribution but Curve's MultiFeeDistribution
/// Example Two: Staking systems. Very common in DeFi. Re-investing/Re-Staking rewards on the Vault level can be included in permissionless way.
contract AaveV2StrategyWrapper is ERC4626 {
    address public immutable manager;
    address public immutable rewardToken;
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant ACTIVE_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
    uint256 internal constant FROZEN_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Aave aToken contract (rebasing)
    ERC20 public immutable aToken;

    /// @notice The Aave-fork liquidity mining contract (implementations can differ)
    IMultiFeeDistribution public immutable rewards;

    /// @notice The Aave LendingPool contract
    ILendingPool public immutable lendingPool;

    /// @notice Pointer to swapInfo
    swapInfo public SwapInfo;

    /// Compact struct to make two swaps (on Uniswap v2)
    /// A => B (using pair1) then B => asset (of Wrapper) (using pair2)
    /// will work fine as long we only get 1 type of reward token
    struct swapInfo {
        address token;
        address pair1;
        address pair2;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        ERC20 asset_,
        ERC20 aToken_,
        IMultiFeeDistribution rewards_, /// @dev Aave-forked protocols often offer alternative reward systems
        ILendingPool lendingPool_,
        address rewardToken_,
        address manager_
    ) ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_)) {
        aToken = aToken_;
        rewards = rewards_;
        lendingPool = lendingPool_;
        rewardToken = rewardToken_;
        manager = manager_;
    }

    /// -----------------------------------------------------------------------
    /// AAVE-Fork Rewards Module
    /// -----------------------------------------------------------------------

    function setRoute(address token, address pair1, address pair2) external {
        require(msg.sender == manager, "onlyOwner");
        SwapInfo = swapInfo(token, pair1, pair2);
        ERC20(rewardToken).approve(SwapInfo.pair1, type(uint256).max); /// max approves address
        ERC20(SwapInfo.token).approve(SwapInfo.pair2, type(uint256).max); /// max approves address
    }

    /// @notice Claims liquidity providing rewards from AAVE-Fork and performs low-lvl swap with instant reinvesting
    /// MultiFeeDistribution on AAVE-Fork accrues AAVE-Fork token as reward for supplying liq
    /// Calling harvest() sells AAVE-Fork token through direct Pair swap for best control and lowest cost
    /// harvest() can be called by anybody. ideally this function should be adjusted per needs (e.g add fee for harvesting)
    function harvest() external {
        /// Example of different than AaveMining rewards implementation of top of Aave-fork
        /// https://github.com/curvefi/multi-rewards
        rewards.getReward();
        rewards.exit();

        uint256 earned = ERC20(rewardToken).balanceOf(address(this));

        /// If one swap needed (high liquidity pair) - set swapInfo.token0/token/pair2 to 0x
        if (SwapInfo.token == address(asset)) {
            DexSwap.swap(
                earned, /// REWARDS amount to swap
                rewardToken, // from REWARD-TOKEN
                address(asset), /// to target underlying of this Vault
                SwapInfo.pair1 /// pairToken (pool)
            );
            /// If two swaps needed
        } else {
            uint256 swapTokenAmount = DexSwap.swap(
                earned,
                rewardToken, // from AAVE-Fork
                SwapInfo.token, /// to intermediary token with high liquidity (no direct pools)
                SwapInfo.pair1 /// pairToken (pool)
            );

            swapTokenAmount = DexSwap.swap(
                swapTokenAmount,
                SwapInfo.token, // from received token
                address(asset), /// to target underlying of this Vault
                SwapInfo.pair2 /// pairToken (pool)
            );
        }

        /// reinvest() without minting (no asset.totalSupply() increase == profit)
        /// afterDeposit just makes totalAssets() aToken's balance growth (to be distributed back to share owners)
        afterDeposit(asset.balanceOf(address(this)), 0);
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// We can't inherit directly from Yield-daddy because of rewardClaim lock
    /// -----------------------------------------------------------------------

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 positions) {
        positions = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - positions;
        }

        beforeWithdraw(assets, positions);

        _burn(owner, positions);

        emit Withdraw(msg.sender, receiver, owner, assets, positions);

        // withdraw assets directly from Aave
        lendingPool.withdraw(address(asset), assets, receiver);
    }

    function redeem(
        uint256 positions,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - positions;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(positions)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, positions);

        _burn(owner, positions);

        emit Withdraw(msg.sender, receiver, owner, assets, positions);

        // withdraw assets directly from Aave
        lendingPool.withdraw(address(asset), assets, receiver);
    }

    function totalAssets() public view virtual override returns (uint256) {
        // aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
        // it's called before every share/asset calculation so it should reflect real value
        return aToken.balanceOf(address(this));
    }

    function afterDeposit(
        uint256 assets,
        uint256 /*positions*/
    ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Aave
        /// -----------------------------------------------------------------------

        // approve to lendingPool
        asset.safeApprove(address(lendingPool), assets);

        // deposit into lendingPool
        lendingPool.deposit(address(asset), assets, address(this), 0);
    }

    function maxDeposit(
        address
    ) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool
            .getReserveData(address(asset))
            .configuration
            .data;
        if (!(_getActive(configData) && !_getFrozen(configData))) {
            return 0;
        }

        return type(uint256).max;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool
            .getReserveData(address(asset))
            .configuration
            .data;
        if (!(_getActive(configData) && !_getFrozen(configData))) {
            return 0;
        }

        return type(uint256).max;
    }

    function maxWithdraw(
        address owner
    ) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool
            .getReserveData(address(asset))
            .configuration
            .data;
        if (!_getActive(configData)) {
            return 0;
        }

        uint256 cash = asset.balanceOf(address(aToken));
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(
        address owner
    ) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool
            .getReserveData(address(asset))
            .configuration
            .data;
        if (!_getActive(configData)) {
            return 0;
        }

        uint256 cash = asset.balanceOf(address(aToken));
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(
        ERC20 asset_
    ) internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("AaveStratERC4626 ", asset_.symbol());
    }

    function _vaultSymbol(
        ERC20 asset_
    ) internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("aS-", asset_.symbol());
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _getActive(uint256 configData) internal pure returns (bool) {
        return configData & ~ACTIVE_MASK != 0;
    }

    function _getFrozen(uint256 configData) internal pure returns (bool) {
        return configData & ~FROZEN_MASK != 0;
    }
}
