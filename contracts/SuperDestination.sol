///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "./interfaces/IERC4626.sol";
import {LiquidityHandler} from "./crosschain-liquidity/LiquidityHandler.sol";
import {StateData, TransactionType, CallbackType, InitData, ReturnData} from "./types/DataTypes.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {IStateRegistry} from "./interfaces/IStateRegistry.sol";
import {ISuperDestination} from "./interfaces/ISuperDestination.sol";

/// @title Super Destination
/// @author Zeropoint Labs.
/// @dev Deposits/Withdraw users funds from an input valid vault.
/// extends Socket's Liquidity Handler.
/// @notice access controlled is expected to be removed due to contract sizing.
contract SuperDestination is ISuperDestination, AccessControl, LiquidityHandler {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    /*///////////////////////////////////////////////////////////////
                     State Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice state variable are all declared public to avoid creating functions to expose.
    
    /// @dev stateRegistry points to the state handler interface deployed in the respective chain.
    IStateRegistry public stateRegistry;

    /// @dev safeGasParam is used while sending layerzero message from destination to router.
    bytes public safeGasParam;
    
    /// @dev chainId represents the layerzero chain id of the specific chain.
    uint256 public chainId;

    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 => address) public bridgeAddress;

    /// @dev maps state data to its unique id for record keeping.
    mapping(uint256 => StateData) public dstState;

    /// @dev maps a vault id to its address.
    mapping(uint256 => IERC4626) public vault;



    /// @notice deploy stateRegistry before SuperDestination
    /// @param chainId_              Layerzero chain id
    /// @param stateRegistry_         State handler address deployed
    /// @dev sets caller as the admin of the contract.
    constructor(uint256 chainId_, IStateRegistry stateRegistry_) {
        chainId = chainId_;
        stateRegistry = stateRegistry_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/    
    receive() external payable {}

    /// @dev handles the state when received from the source chain.
    /// @param payload_     represents the payload id associated with the transaction.
    /// note: called by external keepers when state is ready.
    function stateSync(bytes memory payload_) external payable override {
        require(
            msg.sender == address(stateRegistry),
            "Destination: request denied"
        );
        StateData memory stateData = abi.decode(payload_, (StateData));
        InitData memory data = abi.decode(stateData.params, (InitData));

        for (uint256 i = 0; i < data.vaultIds.length; i++) {
            if (stateData.txType == TransactionType.DEPOSIT) {
                if (
                    IERC20(vault[data.vaultIds[i]].asset()).balanceOf(
                        address(this)
                    ) >= data.amounts[i]
                ) {
                    processDeposit(data);
                } else {
                    revert("Destination: Bridge Tokens Pending");
                }
            } else {
                processWithdrawal(data);
            }
        }
    }

    /// Note PREVILAGED ADMIN ONLY FUNCTION
    /// @dev allows admin to add new vaults to the destination contract.
    /// @notice only added vaults can be used to deposit/withdraw from by users.
    /// @param vaultAddress_ is an array of ERC4626 vault implementations.
    /// @param vaultId_ is an array of unique identifier allocated to each corresponding vault implementation.
    /// Note The whitelisting of vault prevents depositing funds to malicious vaults.
    function addVault(
        IERC4626[] memory vaultAddress_,
        uint256[] memory vaultId_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            vaultAddress_.length == vaultId_.length,
            "Destination: Invalid Length"
        );
        for (uint256 i = 0; i < vaultAddress_.length; i++) {
            require(
                vaultAddress_[i] != IERC4626(address(0)),
                "Destination: Zero Vault Address"
            );

            uint256 id = vaultId_[i];
            vault[id] = vaultAddress_[i];

            uint256 currentAllowance = IERC20(vaultAddress_[i].asset())
                .allowance(address(this), address(vaultAddress_[i]));
            if (currentAllowance == 0) {
                ///@dev pre-approve, only one type of asset is needed anyway
                IERC20(vaultAddress_[i].asset()).safeApprove(
                    address(vaultAddress_[i]),
                    type(uint256).max
                );
            }

            emit VaultAdded(id, vaultAddress_[i]);
        }
    }

    /// @dev PREVILAGED admin ONLY FUNCTION.
    /// @dev adds the gas overrides for layerzero.
    /// @param param_    represents adapterParams V2.0 of layerzero
    function updateSafeGasParam(
        bytes memory param_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(param_.length != 0, "Destination: Invalid Gas Override");
        bytes memory oldParam = safeGasParam;
        safeGasParam = param_;

        emit SafeGasParamUpdated(oldParam, param_);
    }

    /// @dev PREVILAGED admin ONLY FUNCTION.
    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            address x = bridgeAddress_[i];
            uint8 y = bridgeId_[i];
            require(x != address(0), "Router: Zero Bridge Address");

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /// @dev PREVILAGED router ONLY FUNCTION.
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
    )
        external
        payable
        override
        onlyRole(ROUTER_ROLE)
        returns (uint256[] memory dstAmounts)
    {
        uint256 loopLength = vaultIds_.length;
        uint256 expAmount = addValues(amounts_);

        /// note: checking balance
        address collateral = IERC4626(vault[vaultIds_[0]]).asset();
        uint256 balanceBefore = IERC20(collateral).balanceOf(address(this));

        /// note: handle the collateral token transfers.
        if (liqData_.txData.length == 0) {
            require(
                IERC20(liqData_.token).allowance(srcSender_, address(this)) >=
                    liqData_.amount,
                "Destination: Insufficient Allowance"
            );
            IERC20(liqData_.token).safeTransferFrom(
                srcSender_,
                address(this),
                liqData_.amount
            );
        } else {
            dispatchTokens(
                bridgeAddress[liqData_.bridgeId],
                liqData_.txData,
                liqData_.token,
                liqData_.allowanceTarget,
                liqData_.amount,
                srcSender_,
                liqData_.nativeAmount
            );
        }

        uint256 balanceAfter = IERC20(collateral).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore >= expAmount,
            "Destination: Invalid State & Liq Data"
        );

        dstAmounts = new uint256[](loopLength);

        for (uint256 i = 0; i < loopLength; i++) {
            IERC4626 v = vault[vaultIds_[i]];
            require(
                v.asset() == address(collateral),
                "Destination: Invalid Collateral"
            );
            dstAmounts[i] = v.deposit(amounts_[i], address(this));
        }
    }

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
    )
        external
        payable
        override
        onlyRole(ROUTER_ROLE)
        returns (uint256[] memory dstAmounts)
    {
        uint256 len1 = liqData_.txData.length;
        address receiver = len1 == 0 ? address(user_) : address(this);
        dstAmounts = new uint256[](vaultIds_.length);

        address collateral = IERC4626(vault[vaultIds_[0]]).asset();

        for (uint256 i = 0; i < vaultIds_.length; i++) {
            IERC4626 v = vault[vaultIds_[i]];
            require(
                v.asset() == address(collateral),
                "Destination: Invalid Collateral"
            );
            dstAmounts[i] = v.redeem(amounts_[i], receiver, address(this));
        }

        if (len1 != 0) {
            require(
                liqData_.amount <= addValues(dstAmounts),
                "Destination: Invalid Liq Request"
            );

            dispatchTokens(
                bridgeAddress[liqData_.bridgeId],
                liqData_.txData,
                liqData_.token,
                liqData_.allowanceTarget,
                liqData_.amount,
                address(this),
                liqData_.nativeAmount
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Developmental Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILAGED admin ONLY FUNCTION.
    /// @notice should be removed after end-to-end testing.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 tokenContract = IERC20(_tokenContract);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(msg.sender, _amount);
    }

    /// @dev PREVILAGED admin ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function withdrawNativeToken(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(_amount);
    }

    /*///////////////////////////////////////////////////////////////
                            ERC4626 View Functions
    //////////////////////////////////////////////////////////////*/
    /// @dev SuperDestination may need to know state of funds deployed to 3rd party Vaults
    /// @dev API may need to know state of funds deployed
    function previewDepositTo(
        uint256 vaultId_,
        uint256 assets_
    ) public view override returns (uint256) {
        return vault[vaultId_].convertToShares(assets_);
    }

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(
        uint256 vaultId_,
        uint256 assets_
    ) public view override returns (uint256) {
        return vault[vaultId_].previewWithdraw(assets_);
    }

    /// @notice Returns data for single deposit into this vault from SuperRouter (maps user to its balance accross vaults)
    function positionBalance(
        uint256 positionId_
    )
        public
        view
        override
        returns (uint256[] memory vaultIds, uint256[] memory destAmounts)
    {
        InitData memory initData = abi.decode(
            dstState[positionId_].params,
            (InitData)
        );

        return (
            initData.vaultIds,
            initData.amounts /// @dev amount of tokens bridged from source (input to vault.deposit())
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/
    
    /// @dev process valid deposit data and deposit collateral.
    /// @dev What if vault.asset() isn't the same as bridged token?
    /// @param data_     represents state data from router of another chain
    function processDeposit(InitData memory data_) internal {
        /// @dev Ordering dependency vaultIds need to match dstAmounts (shadow matched to user)
        uint256[] memory dstAmounts = new uint256[](data_.vaultIds.length);
        for (uint256 i = 0; i < data_.vaultIds.length; i++) {
            IERC4626 v = vault[data_.vaultIds[i]];

            dstAmounts[i] = v.deposit(data_.amounts[i], address(this));
            /// @notice dstAmounts is equal to POSITIONS returned by v(ault)'s deposit while data.amounts is equal to ASSETS (tokens) bridged
            emit Processed(
                data_.srcChainId,
                data_.dstChainId,
                data_.txId,
                data_.amounts[i],
                data_.vaultIds[i]
            );
        }

        /// Note Step-4: Send Data to Source to issue superform positions.
        stateRegistry.dispatchPayload{value: msg.value}(
            1, /// @dev come to this later to accept any bridge id
            data_.srcChainId,
            abi.encode(
                StateData(
                    TransactionType.DEPOSIT,
                    CallbackType.RETURN,
                    abi.encode(
                        ReturnData(
                            true,
                            data_.srcChainId,
                            chainId,
                            data_.txId,
                            dstAmounts
                        )
                    )
                )
            ),
            safeGasParam
        );
    }

    /// @dev process valid withdrawal data and remove collateral.
    /// @param data_     represents state data from router of another chain
    function processWithdrawal(InitData memory data_) internal {
        uint256[] memory dstAmounts = new uint256[](data_.vaultIds.length);
        LiqRequest memory _liqData = abi.decode(data_.liqData, (LiqRequest));

        for (uint256 i = 0; i < data_.vaultIds.length; i++) {
            if (_liqData.txData.length != 0) {
                IERC4626 v = vault[data_.vaultIds[i]];
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmounts[i] = v.redeem(
                    data_.amounts[i],
                    address(this),
                    address(this)
                );

                uint256 balanceBefore = IERC20(v.asset()).balanceOf(
                    address(this)
                );
                /// Note Send Tokens to Source Chain
                /// FEAT Note: We could also allow to pass additional chainId arg here
                /// FEAT Note: Requires multiple ILayerZeroEndpoints to be mapped
                dispatchTokens(
                    bridgeAddress[_liqData.bridgeId],
                    _liqData.txData,
                    _liqData.token,
                    _liqData.allowanceTarget,
                    dstAmounts[i],
                    address(this),
                    _liqData.nativeAmount
                );
                uint256 balanceAfter = IERC20(v.asset()).balanceOf(
                    address(this)
                );

                /// note: balance validation to prevent draining contract.
                require(
                    balanceAfter >= balanceBefore - dstAmounts[i],
                    "Destination: Invalid Liq Request"
                );
            } else {
                IERC4626 v = vault[data_.vaultIds[i]];
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmounts[i] = v.redeem(
                    data_.amounts[i],
                    address(data_.user),
                    address(this)
                );
            }

            emit Processed(
                data_.srcChainId,
                data_.dstChainId,
                data_.txId,
                dstAmounts[i],
                data_.vaultIds[i]
            );
        }
    }

    /// @dev returns the sum of an array.
    /// @param amounts_ represents an array of inputs.
    function addValues(
        uint256[] memory amounts_
    ) internal pure returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < amounts_.length; i++) {
            total += amounts_[i];
        }
        return total;
    }
}
