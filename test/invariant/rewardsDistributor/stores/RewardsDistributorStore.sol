// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev Storage variables needed by all vault shares handlers.
contract RewardsDistributorStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public usdcBalanceAfter;
    uint256 public daiBalanceAfter;

    uint256 public usdcBalanceBeforeWithChange;
    uint256 public daiBalanceBeforeWithChange;

    uint256 public totalSelectedUsers;
    uint256 public totalTestUsers;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setUSDCBalanceAfter(uint256 _usdcBalanceAfter) external {
        usdcBalanceAfter = _usdcBalanceAfter;
    }

    function setDAIBalanceAfter(uint256 _daiBalanceAfter) external {
        daiBalanceAfter = _daiBalanceAfter;
    }

    function setUSDCBalanceBeforeWithChange(uint256 _usdcBalanceBeforeWithChange) external {
        usdcBalanceBeforeWithChange = _usdcBalanceBeforeWithChange;
    }

    function setDAIBalanceBeforeWithChange(uint256 _daiBalanceBeforeWithChange) external {
        daiBalanceBeforeWithChange = _daiBalanceBeforeWithChange;
    }

    function setTotalSelectedUsers(uint256 _totalSelectedUsers) external {
        totalSelectedUsers = _totalSelectedUsers;
    }

    function setTotalTestUsers(uint256 _totalTestUsers) external {
        totalTestUsers = _totalTestUsers;
    }
}
