// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiqRequest} from "../types/LiquidityTypes.sol";
import {IERC4626} from "../interfaces/IERC4626.sol";

interface ISuperDestination {
    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new vault is added by the admin.
    event VaultAdded(uint256 id, IERC4626 vault);

    /// @dev is emitted when a payload is processed by the destination contract.
    event Processed(
        uint256 srcChainID,
        uint256 dstChainId,
        uint256 txId,
        uint256 amounts,
        uint256 vaultId
    );

    /// @dev is emitted when layerzero safe gas params are updated.
    event SafeGasParamUpdated(bytes oldParam, bytes newParam);

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 bridgeId, address bridgeAddress);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows state registry contract to send payload for processing to the destination contract.
    /// @param payload_ is the received information to be processed.
    function stateSync(bytes memory payload_) external payable;

    /// @dev allows admin to add new vaults to the destination contract.
    /// @notice only added vaults can be used to deposit/withdraw from by users.
    /// @param vaultAddress_ is an array of ERC4626 vault implementations.
    /// @param vaultId_ is an array of unique identifier allocated to each corresponding vault implementation.
    function addVault(
        IERC4626[] memory vaultAddress_,
        uint256[] memory vaultId_
    ) external;

    /// @dev adds the gas overrides for layerzero.
    /// @param param_    represents adapterParams V2.0 of layerzero
    function updateSafeGasParam(bytes memory param_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external;

    /// @dev process same chain id deposits
    /// @param srcSender_  represents address of the depositing user.
    /// @param liqData_ represents swap information to be executed before depositing.
    /// @param vaultIds_  array of vaultIds on the chain to make a deposit
    /// @param amounts_   array of amounts to be deposited in each corresponding _vaultIds
    /// @return dstAmounts the amount of shares minted
    function directDeposit(
        address srcSender_,
        LiqRequest calldata liqData_,
        uint256[] memory vaultIds_,
        uint256[] memory amounts_
    ) external payable returns (uint256[] memory dstAmounts);

    /// @dev PREVILAGED router ONLY FUNCTION.
    /// @dev process withdrawal of collateral from a vault
    /// @param user_     represents address of the depositing user.
    /// @param vaultIds_  array of vaultIds on the chain to make a deposit
    /// @param amounts_  array of amounts to be deposited in each corresponding _vaultIds
    /// @return dstAmounts the amount of shares redeemed
    function directWithdraw(
        address user_,
        uint256[] memory vaultIds_,
        uint256[] memory amounts_,
        LiqRequest memory liqData_
    ) external payable returns (uint256[] memory dstAmounts);

    /*///////////////////////////////////////////////////////////////
                            ERC4626 View Functions
    //////////////////////////////////////////////////////////////*/
    /// @dev SuperDestination may need to know state of funds deployed to 3rd party Vaults
    /// @dev API may need to know state of funds deployed
    function previewDepositTo(uint256 vaultId, uint256 assets)
        external
        view
        returns (uint256);

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(uint256 vaultId, uint256 assets)
        external
        view
        returns (uint256);

    /// @notice Returns data for single deposit into this vault from SuperRouter (maps user to its balance accross vaults)
    function positionBalance(uint256 positionId)
        external
        view
        returns (uint256[] memory vaultIds, uint256[] memory destAmounts);
}
