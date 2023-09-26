/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../utils/ProtocolActions.sol";
import "./handlers/VaultSharesHandler.sol";
import "forge-std/Test.sol";

contract VaultSharesInvariantTest is Test, ProtocolActions {
    VaultSharesHandler public handler;
    address[][] allAddresses;
    address[][] underlyingAddresses;
    address[][] vaultAddresses;
    address[][] superformAddresses;

    function setUp() public override {
        super.setUp();

        for (uint256 i = 0; i < chainIds.length; i++) {
            address[] memory addresses = new address[](contractNames.length);
            for (uint256 j = 0; j < contractNames.length; j++) {
                addresses[j] = getContract(chainIds[i], contractNames[j]);
            }
            allAddresses.push(addresses);

            addresses = new address[](UNDERLYING_TOKENS.length);

            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                addresses[j] = getContract(chainIds[i], UNDERLYING_TOKENS[j]);
            }
            underlyingAddresses.push(addresses);
        }
        handler = new VaultSharesHandler(allAddresses, chainIds, contractNames);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = VaultSharesHandler.singleDirectSingleVaultDeposit.selector;
        //selectors[1] = VaultSharesHandler.singleDirectSingleVaultWithdraw.selector;
        //selectors[2] = VaultSharesHandler.singleXChainRescueFailedDeposit.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function invariant_vaultShares() public {
        /*
        /// @dev target superform: (underlying, vault, formKind, chain) = (1, 0, 0, 1)
        uint256 superPositionsSum;
        /// @dev sum up superpositions owned by user for the superform on ETH, on all chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256[] memory superPositions = _getSuperpositionsForDstChainFromSrcChain(
        0, TARGET_UNDERLYINGS[AVAX][0], TARGET_VAULTS[AVAX][0], TARGET_FORM_KINDS[AVAX][0], chainIds[i], AVAX
            );

            if (superPositions.length > 0) {
                superPositionsSum += superPositions[0];
            }
        }

        address superform = getContract(
        AVAX, string.concat(UNDERLYING_TOKENS[2], VAULT_KINDS[0], "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        vm.selectFork(FORKS[AVAX]);
        console.log("superPositionsSum:", superPositionsSum);
        console.log("vaultShares:", IBaseForm(superform).getVaultShareBalance());
        assertEq(superPositionsSum, IBaseForm(superform).getVaultShareBalance());
        */
        assertEq(handler.getSuperpositionsSum(), handler.getVaultShares());
    }

    /*
    function invariant_singleDirectSingleVaultDeposit() public {
        AMBs = [2, 3];
        CHAIN_0 = AVAX;
        DST_CHAINS = [AVAX];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2];
        TARGET_VAULTS[AVAX][0] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][0] = [0];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[AVAX][0] = [0];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 999, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        AMOUNTS[AVAX][0] = [8_000_000];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }

        actions.pop();
        console.log("dep");

        /// @dev target superform: (underlying, vault, formKind, chain) = (1, 0, 0, 1)
        uint256 superPositionsSum;
        /// @dev sum up superpositions owned by user for the superform on ETH, on all chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256[] memory superPositions = _getSuperpositionsForDstChainFromSrcChain(
    0, TARGET_UNDERLYINGS[AVAX][0], TARGET_VAULTS[AVAX][0], TARGET_FORM_KINDS[AVAX][0], chainIds[i], AVAX
            );

            if (superPositions.length > 0) {
                superPositionsSum += superPositions[0];
            }
        }

        address superform = getContract(
    AVAX, string.concat(UNDERLYING_TOKENS[2], VAULT_KINDS[0], "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        vm.selectFork(FORKS[AVAX]);
        console.log("superPositionsSum:", superPositionsSum);
        console.log("vaultShares:", IBaseForm(superform).getVaultShareBalance());
        assertEq(superPositionsSum, IBaseForm(superform).getVaultShareBalance());

        //assertEq(handler.getSuperpositionsSum(), handler.getVaultShares());
    }
    */
}

/// define getters in handler that return addresses of target superform and target superposition
