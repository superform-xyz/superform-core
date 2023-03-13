// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {LiqRequest} from "../types/LiquidityTypes.sol";
import {IERC4626} from "./IERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBaseForm is IERC165 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new vault is added by the admin.
    event VaultAdded(uint256 id, IERC4626 vault);

    /// @dev is emitted when a payload is processed by the destination contract.
    event Processed(
        uint256 srcChainID,
        uint256 dstChainId,
        uint256 txId,
        uint256 amounts,
        address vault
    );

    /// @dev is emitted when layerzero safe gas params are updated.
    event SafeGasParamUpdated(bytes oldParam, bytes newParam);

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 bridgeId, address bridgeAddress);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id brought in the cross chain message is invalid
    error INVALID_CHAIN_ID();

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WRITE FUNCTONS
    //////////////////////////////////////////////////////////////*/

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

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param formData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function directDepositIntoVault(
        bytes calldata formData_
    ) external payable returns (uint256[] memory dstAmounts);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param formData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function xChainDepositIntoVault(
        bytes calldata formData_
    ) external payable returns (uint256[] memory dstAmounts);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param formData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens withdrawn in same chain action
    function directWithdrawFromVault(
        bytes memory formData_
    ) external payable returns (uint256[] memory dstAmounts);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param formData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens withdrawn in same chain action
    function xChainWithdrawFromVault(
        bytes memory formData_
    ) external payable returns (uint256[] memory dstAmounts);

    function getUnderlyingOfVault(address vault) external view returns (ERC20);
}
