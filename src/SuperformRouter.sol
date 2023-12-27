// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseRouterImplementation } from "src/BaseRouterImplementation.sol";
import { BaseRouter } from "src/BaseRouter.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import "src/types/DataTypes.sol";

/// @title SuperformRouter
/// @dev Routes funds and action information to a remote execution chain
/// @author Zeropoint Labs
contract SuperformRouter is BaseRouterImplementation {

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) BaseRouterImplementation(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectSingleVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainSingleVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectMultiVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainMultiVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;

        for (uint256 i; i < len; ++i) {
            if (CHAIN_ID == req_.dstChainIds[i]) {
                _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;

        for (uint256 i; i < len; ++i) {
            if (CHAIN_ID == req_.dstChainIds[i]) {
                _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainMultiVaultDeposit(
                    SingleXChainMultiVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectSingleVaultWithdraw(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainSingleVaultWithdraw(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectMultiVaultWithdraw(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainMultiVaultWithdraw(req_);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;

        for (uint256 i; i < len; ++i) {
            if (CHAIN_ID == req_.dstChainIds[i]) {
                _singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainSingleVaultWithdraw(
                    SingleXChainSingleVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;

        for (uint256 i; i < len; ++i) {
            if (CHAIN_ID == req_.dstChainIds[i]) {
                _singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainMultiVaultWithdraw(
                    SingleXChainMultiVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function forwardDustToPaymaster(address token_) external override(BaseRouter, IBaseRouter) {
        _forwardDustToPaymaster(token_);
    }
}
