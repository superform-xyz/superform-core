// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev Storage variables needed by all vault shares handlers.
contract RewardsDistributorStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    uint256 public usdcBalanceAfter;
    uint256 public daiBalanceAfter;

    mapping(uint256 => uint256) public totalSelectedUsersPeriod;
    mapping(uint256 => uint256) public totalTestUsersPeriod;

    uint256 public totalPeriodsSelected;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setUSDCBalanceAfter(uint256 _usdcBalanceAfter) external {
        usdcBalanceAfter = _usdcBalanceAfter;
    }

    function setDAIBalanceAfter(uint256 _daiBalanceAfter) external {
        daiBalanceAfter = _daiBalanceAfter;
    }

    function setTotalSelectedUsers(uint256 periodId, uint256 _totalSelectedUsers) external {
        totalSelectedUsersPeriod[periodId] = _totalSelectedUsers;
    }

    function setTotalTestUsers(uint256 periodId, uint256 _totalTestUsers) external {
        totalTestUsersPeriod[periodId] = _totalTestUsers;
    }

    function setTotalPeriodsSelected(uint256 _totalPeriodsSelected) external {
        totalPeriodsSelected = _totalPeriodsSelected;
    }
}
