/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { BaseRouterImplementation } from "./BaseRouterImplementation.sol";
import { BaseRouter } from "./BaseRouter.sol";
import { IBaseRouter } from "./interfaces/IBaseRouter.sol";
import "./types/DataTypes.sol";

/// @title SuperformRouter
/// @author Zeropoint Labs.
/// @dev SuperformRouter users funds and action information to a remote execution chain.
/// @dev Uses standard BaseRouterImplementation without any overrides to internal execution functions
contract SuperformRouter is BaseRouterImplementation {
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    /// @param stateRegistryType_ the state registry type
    /// @param routerType_ the router type
    constructor(
        address superRegistry_,
        uint8 stateRegistryType_,
        uint8 routerType_
    )
        BaseRouterImplementation(superRegistry_, stateRegistryType_, routerType_)
    { }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBaseRouter
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 chainId = uint64(block.chainid);
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req.dstChainIds.length;
        for (uint256 i; i < len;) {
            if (chainId == req.dstChainIds[i]) {
                _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq(req.superformsData[i]));
            } else {
                _singleXChainMultiVaultDeposit(
                    SingleXChainMultiVaultStateReq(req.ambIds[i], req.dstChainIds[i], req.superformsData[i])
                );
            }
            unchecked {
                ++i;
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint64 srcChainId = uint64(block.chainid);
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req.dstChainIds.length;

        for (uint256 i; i < len;) {
            if (srcChainId == req.dstChainIds[i]) {
                _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq(req.superformsData[i]));
            } else {
                _singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(req.ambIds[i], req.dstChainIds[i], req.superformsData[i])
                );
            }
            unchecked {
                ++i;
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainMultiVaultDeposit(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainSingleVaultDeposit(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectMultiVaultDeposit(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectSingleVaultDeposit(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 chainId = uint64(block.chainid);
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req.dstChainIds.length;

        for (uint256 i; i < len;) {
            if (chainId == req.dstChainIds[i]) {
                _singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq(req.superformsData[i]));
            } else {
                _singleXChainMultiVaultWithdraw(
                    SingleXChainMultiVaultStateReq(req.ambIds[i], req.dstChainIds[i], req.superformsData[i])
                );
            }

            unchecked {
                ++i;
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req.dstChainIds.length;

        for (uint256 i; i < len;) {
            if (uint64(block.chainid) == req.dstChainIds[i]) {
                _singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq(req.superformsData[i]));
            } else {
                _singleXChainSingleVaultWithdraw(
                    SingleXChainSingleVaultStateReq(req.ambIds[i], req.dstChainIds[i], req.superformsData[i])
                );
            }
            unchecked {
                ++i;
            }
        }

        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainMultiVaultWithdraw(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleXChainSingleVaultWithdraw(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectMultiVaultWithdraw(req);
        _forwardPayment(balanceBefore);
    }

    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectSingleVaultWithdraw(req);
        _forwardPayment(balanceBefore);
    }
}
