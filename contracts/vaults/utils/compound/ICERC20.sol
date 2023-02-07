// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

import {IInterestRateModel} from "./IInterestRateModel.sol";

abstract contract ICERC20 is ERC20 {
    function mint(uint256 underlyingAmount) external virtual returns (uint256);

    function underlying() external view virtual returns (ERC20);

    function getCash() external view virtual returns (uint256);

    function totalBorrows() external view virtual returns (uint256);

    function totalReserves() external view virtual returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function accrualBlockNumber() external view virtual returns (uint256);

    function redeemUnderlying(uint256 underlyingAmount)
        external
        virtual
        returns (uint256);

    function balanceOfUnderlying(address) external virtual returns (uint256);

    function reserveFactorMantissa() external view virtual returns (uint256);

    function interestRateModel()
        external
        view
        virtual
        returns (IInterestRateModel);

    function initialExchangeRateMantissa()
        external
        view
        virtual
        returns (uint256);
}
