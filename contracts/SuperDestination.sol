/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "./interface/IERC4626.sol";

import {StateHandler} from "./layerzero/stateHandler.sol";
import {LiquidityHandler} from "./socket/liquidityHandler.sol";

import {StateData, TransactionType, CallbackType, InitData, ReturnData} from "./types/lzTypes.sol";
import {LiqRequest} from "./types/socketTypes.sol";
import {IStateHandler} from "./interface/layerzero/IStateHandler.sol";

import "hardhat/console.sol";

/**
 * @title Super Destination
 * @author Zeropoint Labs.
 *
 * Deposits/Withdraw users funds from an input valid vault.
 * extends Socket's Liquidity Handler.
 * @notice access controlled is expected to be removed due to contract sizing.
 */
contract SuperDestination is AccessControl, LiquidityHandler {
    using SafeERC20 for IERC20;

    /* ================ Constants =================== */
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    /* ================ State Variables =================== */

    /**
     * @notice state variable are all declared public to avoid creating functions to expose.
     *
     * @dev stateHandler points to the state handler interface deployed in the respective chain.
     * @dev safeGasParam is used while sending layerzero message from destination to router.
     * @dev chainId represents the layerzero chain id of the specific chain.
     */
    IStateHandler public stateHandler;
    bytes public safeGasParam;
    uint16 public chainId;

    /**
     * @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
     * @dev maps state data to its unique id for record keeping.
     * @dev maps a vault id to its address.
     */
    mapping(uint8 => address) public bridgeAddress;
    mapping(uint256 => StateData) public dstState;
    mapping(uint256 => IERC4626) public vault;
    mapping(uint16 => address) public shareHandler;

    /* ================ Events =================== */

    event VaultAdded(uint256 id, IERC4626 vault);
    event TokenDistributorAdded(address routerAddress, uint16 chainId);
    event Processed(
        uint16 srcChainID,
        uint16 dstChainId,
        uint256 txId,
        uint256 amounts,
        uint256 vaultId
    );
    event SafeGasParamUpdated(bytes oldParam, bytes newParam);
    event SetBridgeAddress(uint256 bridgeId, address bridgeAddress);

    /* ================ Constructor =================== */
    /**
     * @notice deploy stateHandler before SuperDestination
     *
     * @param chainId_              Layerzero chain id
     * @param stateHandler_         State handler address deployed
     *
     * @dev sets caller as the admin of the contract.
     */
    constructor(uint16 chainId_, IStateHandler stateHandler_) {
        chainId = chainId_;
        stateHandler = stateHandler_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* ================ Write Functions =================== */
    receive() external payable {}

    /**
     * @dev handles the state when received from the source chain.
     *
     * @param _payload     represents the payload id associated with the transaction.
     *
     * Note: called by external keepers when state is ready.
     */
    function stateSync(bytes memory _payload) external payable {
        require(
            msg.sender == address(stateHandler),
            "Destination: request denied"
        );
        StateData memory stateData = abi.decode(_payload, (StateData));
        InitData memory data = abi.decode(stateData.params, (InitData));

        for (uint256 i = 0; i < data.vaultIds.length; i++) {
            if (stateData.txType == TransactionType.DEPOSIT) {
                /// NOTE: Validate that this are payload sender tokens
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

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @dev Soon to be moved to a factory contract. (Post Wormhole Implementation)
     *
     * @param _vaultAddress     address of ERC4626 interface compilant Vault
     * @param _vaultId          represents the unique vault id added to a vault.
     *
     * Note The whitelisting of vault prevents depositing funds to malicious vaults.
     */
    function addVault(
        IERC4626[] memory _vaultAddress,
        uint256[] memory _vaultId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _vaultAddress.length == _vaultId.length,
            "Destination: Invalid Length"
        );
        for (uint256 i = 0; i < _vaultAddress.length; i++) {
            require(
                _vaultAddress[i] != IERC4626(address(0)),
                "Destination: Zero Vault Address"
            );

            uint256 id = _vaultId[i];
            vault[id] = _vaultAddress[i];

            uint256 currentAllowance = IERC20(_vaultAddress[i].asset())
                .allowance(address(this), address(_vaultAddress[i]));
            if (currentAllowance == 0) {
                ///@dev pre-approve, only one type of asset is needed anyway
                IERC20(_vaultAddress[i].asset()).safeApprove(
                    address(_vaultAddress[i]),
                    type(uint256).max
                );
            }

            emit VaultAdded(id, _vaultAddress[i]);
        }
    }

    /**
     * PREVILAGED admin ONLY FUNCTION.
     *
     * @dev whitelists the router contract of different chains.
     * @param _positionsHandler    represents the address of router contract.
     * @param _srcChainId       represents the chainId of the source contract.
     */
    function setSrcTokenDistributor(
        address _positionsHandler,
        uint16 _srcChainId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_positionsHandler != address(0), "Destination: Zero Address");
        require(_srcChainId != 0, "Destination: Invalid Chain Id");

        shareHandler[_srcChainId] = _positionsHandler;

        /// @dev because directDeposit/Withdraw is only happening from the sameChain, we can use this param
        _setupRole(ROUTER_ROLE, _positionsHandler);
        emit TokenDistributorAdded(_positionsHandler, _srcChainId);
    }

    /**
     * PREVILAGED admin ONLY FUNCTION.
     *
     * @dev adds the gas overrides for layerzero.
     * @param _param    represents adapterParams V2.0 of layerzero
     */
    function updateSafeGasParam(bytes memory _param)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_param.length != 0, "Destination: Invalid Gas Override");
        bytes memory oldParam = safeGasParam;
        safeGasParam = _param;

        emit SafeGasParamUpdated(oldParam, _param);
    }

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @dev allows admin to set the bridge address for an bridge id.
     * @param _bridgeId         represents the bridge unqiue identifier.
     * @param _bridgeAddress    represents the bridge address.
     */
    function setBridgeAddress(
        uint8[] memory _bridgeId,
        address[] memory _bridgeAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _bridgeId.length; i++) {
            address x = _bridgeAddress[i];
            uint8 y = _bridgeId[i];
            require(x != address(0), "Router: Zero Bridge Address");

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /**
     * PREVILAGED router ONLY FUNCTION.
     *
     * @dev process same chain id deposits
     * @param srcSender  represents address of the depositing user.
     * @param _vaultIds  array of vaultIds on the chain to make a deposit
     * @param _amounts   array of amounts to be deposited in each corresponding _vaultIds
     */
    function directDeposit(
        address srcSender,
        LiqRequest calldata liqData,
        uint256[] memory _vaultIds,
        uint256[] memory _amounts
    )
        external
        payable
        onlyRole(ROUTER_ROLE)
        returns (uint256[] memory dstAmounts)
    {
        /// NOTE: Why do we loop here? singleDeposit already happens in a loop?
        uint256 loopLength = _vaultIds.length;
        uint256 expAmount = addValues(_amounts);

        /// note: checking balance
        address collateral = IERC4626(vault[_vaultIds[0]]).asset();
        uint256 balanceBefore = IERC20(collateral).balanceOf(address(this));

        /// note: handle the collateral token transfers.
        /// NOTE: Leaky check here. Manipulated LiqData can be sent to execute either in sameChain or crossChain context
        /// NOTE: This also led to reliance on _isERC20 argument to pass tokens between Router and Destination
        console.log("LiqData Length: ", liqData.txData.length);
        if (liqData.txData.length == 0) {
            console.log("allowance", IERC20(liqData.token).allowance(srcSender, address(this)));
            console.log("liqData.amount", liqData.amount);
            /// NOTE: Probably code was failing here b4, that's why decission was to route through dispatch()
            require(
                IERC20(liqData.token).allowance(srcSender, address(this)) >=
                    liqData.amount,
                "Destination: Insufficient Allowance"
            );
            IERC20(liqData.token).safeTransferFrom(
                srcSender,
                address(this),
                liqData.amount
            );
        } else {
            dispatchTokens(
                bridgeAddress[liqData.bridgeId],
                liqData.txData,
                liqData.token,
                liqData.isERC20,
                liqData.amount,
                srcSender,
                liqData.nativeAmount
            );
        }

        uint256 balanceAfter = IERC20(collateral).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore >= expAmount,
            "Destination: Invalid State & Liq Data"
        );

        dstAmounts = new uint256[](loopLength);

        for (uint256 i = 0; i < loopLength; i++) {
            IERC4626 v = vault[_vaultIds[i]];
            require(
                v.asset() == address(collateral),
                "Destination: Invalid Collateral"
            );
            dstAmounts[i] = v.deposit(_amounts[i], address(this));
        }
    }

    /**
     * PREVILAGED router ONLY FUNCTION.
     *
     * @dev process withdrawal of collateral from a vault
     * @param _user     represents address of the depositing user.
     * @param _vaultIds  array of vaultIds on the chain to make a deposit
     * @param _amounts  array of amounts to be deposited in each corresponding _vaultIds
     */
    function directWithdraw(
        address _user,
        uint256[] memory _vaultIds,
        uint256[] memory _amounts,
        LiqRequest memory _liqData
    )
        external
        payable
        onlyRole(ROUTER_ROLE)
        returns (uint256[] memory dstAmounts)
    {
        uint256 len1 = _liqData.txData.length;
        address receiver = len1 == 0 ? address(_user) : address(this);
        dstAmounts = new uint256[](_vaultIds.length);

        address collateral = IERC4626(vault[_vaultIds[0]]).asset();

        for (uint256 i = 0; i < _vaultIds.length; i++) {
            IERC4626 v = vault[_vaultIds[i]];
            require(
                v.asset() == address(collateral),
                "Destination: Invalid Collateral"
            );
            dstAmounts[i] = v.redeem(_amounts[i], receiver, address(this));
        }

        if (len1 != 0) {
            /// @dev this check worked on localhost, but failed on mainnet
            require(
                _liqData.amount <= addValues(dstAmounts),
                "Destination: Invalid Liq Request"
            );

            dispatchTokens(
                bridgeAddress[_liqData.bridgeId],
                _liqData.txData,
                _liqData.token,
                _liqData.isERC20,
                _liqData.amount,
                address(this),
                _liqData.nativeAmount
            );
        }
    }

    /* ================ Development Only Functions =================== */

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @notice should be removed after end-to-end testing.
     * @dev allows admin to withdraw lost tokens in the smart contract.
     */
    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(msg.sender, _amount);
    }

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @dev allows admin to withdraw lost native tokens in the smart contract.
     */
    function withdrawNativeToken(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(msg.sender).transfer(_amount);
    }

    /* ================ ERC4626 View Functions =================== */

    /**
     * @dev SuperDestination may need to know state of funds deployed to 3rd party Vaults
     * @dev API may need to know state of funds deployed
     */
    function previewDepositTo(uint256 vaultId, uint256 assets)
        public
        view
        returns (uint256)
    {
        return vault[vaultId].convertToShares(assets);
    }

    /**
     * @notice positionBalance() -> .vaultIds&destAmounts
     * @return how much of an asset + interest (accrued) is to withdraw from the Vault
     */
    function previewWithdrawFrom(uint256 vaultId, uint256 assets)
        public
        view
        returns (uint256)
    {
        return vault[vaultId].previewWithdraw(assets);
    }

    /**
     * @notice Returns data for single deposit into this vault from SuperRouter (maps user to its balance accross vaults)
     */
    function positionBalance(uint256 positionId)
        public
        view
        returns (uint256[] memory vaultIds, uint256[] memory destAmounts)
    {
        InitData memory initData = abi.decode(
            dstState[positionId].params,
            (InitData)
        );

        return (
            initData.vaultIds,
            initData.amounts /// @dev amount of tokens bridged from source (input to vault.deposit())
        );
    }

    /* ================ Internal Functions =================== */

    /**
     * @dev process valid deposit data and deposit collateral.
     * @dev What if vault.asset() isn't the same as bridged token?
     * @param data     represents state data from router of another chain
     */
    function processDeposit(InitData memory data) internal {
        /// @dev Ordering dependency vaultIds need to match dstAmounts (shadow matched to user)
        uint256[] memory dstAmounts = new uint256[](data.vaultIds.length);
        for (uint256 i = 0; i < data.vaultIds.length; i++) {
            IERC4626 v = vault[data.vaultIds[i]];

            /// NOTE: How do we validate that _liqData.amount is >= stateData.amounts
            /// NOTE: Old SUP-633
            dstAmounts[i] = v.deposit(data.amounts[i], address(this));
            /// @notice dstAmounts is equal to POSITIONS returned by v(ault)'s deposit while data.amounts is equal to ASSETS (tokens) bridged
            emit Processed(
                data.srcChainId,
                data.dstChainId,
                data.txId,
                data.amounts[i],
                data.vaultIds[i]
            );
        }
        /// Note Step-4: Send Data to Source to issue superform positions.
        stateHandler.dispatchState{value: msg.value}(
            data.srcChainId,
            abi.encode(
                StateData(
                    TransactionType.DEPOSIT,
                    CallbackType.RETURN,
                    abi.encode(
                        ReturnData(
                            true,
                            data.srcChainId,
                            chainId,
                            data.txId,
                            dstAmounts
                        )
                    )
                )
            ),
            safeGasParam
        );
    }

    /**
     * @dev process valid withdrawal data and remove collateral.
     * @param data     represents state data from router of another chain
     */
    function processWithdrawal(InitData memory data) internal {
        uint256[] memory dstAmounts = new uint256[](data.vaultIds.length);
        LiqRequest memory _liqData = abi.decode(data.liqData, (LiqRequest));

        for (uint256 i = 0; i < data.vaultIds.length; i++) {
            if (_liqData.txData.length != 0) {
                IERC4626 v = vault[data.vaultIds[i]];
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmounts[i] = v.redeem(
                    data.amounts[i],
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
                    _liqData.isERC20,
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
                IERC4626 v = vault[data.vaultIds[i]];
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmounts[i] = v.redeem(
                    data.amounts[i],
                    address(data.user),
                    address(this)
                );
            }

            emit Processed(
                data.srcChainId,
                data.dstChainId,
                data.txId,
                dstAmounts[i],
                data.vaultIds[i]
            );
        }
    }

    function addValues(uint256[] memory amounts)
        internal
        pure
        returns (uint256)
    {
        uint256 total;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}
