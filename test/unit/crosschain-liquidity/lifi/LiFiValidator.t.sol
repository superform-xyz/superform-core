// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import "src/interfaces/IBridgeValidator.sol";
import { GenericSwapFacet } from "src/vendor/lifi/GenericSwapFacet.sol";

contract LiFiValidatorTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
    }

    function test_lifi_validator() public {
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        BSC,
                        uint256(100),
                        getContract(BSC, "CoreStateRegistry"),
                        false
                    )
                ),
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_lifi_validator_blacklistedSelector() public {
        vm.prank(deployer);
        LiFiValidator(getContract(ETH, "LiFiValidator")).addToBlacklist(bytes4(keccak256("blacklistedFunction()")));

        bytes memory txData = abi.encodeWithSignature("blacklistedFunction()");

        vm.expectRevert(Error.BLACKLISTED_SELECTOR.selector);
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_sameSrcDstChainId() public {
        vm.expectRevert(Error.INVALID_ACTION.selector);
        // Call validateTxData with srcChainId equal to dstChainId
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        ETH, // srcChainId is the same as dstChainId
                        uint256(100),
                        getContract(ETH, "CoreStateRegistry"),
                        false
                    )
                ),
                ETH,
                ETH, // srcChainId is the same as dstChainId
                ETH,
                true,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_lifi_validator_invalidInterimToken() public {
        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        BSC,
                        uint256(100),
                        getContract(BSC, "DstSwapper"),
                        false
                    )
                ),
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                deployer,
                NATIVE,
                address(0)
            )
        );
    }

    function test_lifi_invalid_receiver() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "PayMaster"), false
            )
        );
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_dstchain() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                address(0),
                address(0),
                deployer,
                ETH,
                BSC,
                uint256(100),
                getContract(BSC, "CoreStateRegistry"),
                false
            )
        );
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, ARBI, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_receiver_samechain() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, ETH, uint256(100), getContract(ETH, "PayMaster"), true
            )
        );
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ETH, ETH, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_receiver_xchain_withdraw() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, OP, uint256(100), getContract(OP, "PayMaster"), false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, OP, false, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_txdata_chainid_withdraw() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, OP, uint256(100), getContract(OP, "PayMaster"), false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, ARBI, false, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_token() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                address(0),
                address(0),
                deployer,
                ETH,
                ARBI,
                uint256(100),
                getContract(ARBI, "CoreStateRegistry"),
                false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData, ETH, ARBI, ARBI, true, address(0), deployer, address(420), NATIVE
            )
        );
    }

    function test_extractGenericSwap_standardizedCallInterface() public {
        bytes memory data = abi.encodeWithSelector(
            0xd6a4bc50,
            _buildDummyTxDataUnitTests(
                BuildDummyTxDataUnitTestsVars(
                    1,
                    address(0),
                    address(0),
                    deployer,
                    ETH,
                    ETH,
                    uint256(100),
                    getContract(ETH, "CoreStateRegistry"),
                    true
                )
            )
        );

        (,, address receiver,,) = LiFiValidator(getContract(ETH, "LiFiValidator")).extractGenericSwapParameters(data);

        assertEq(receiver, getContract(ETH, "CoreStateRegistry"));
    }

    /// to CSR
    function test_lifi_validator_realDataStargateCSR() public {
        bytes memory stargateDataGeneratedOffChain =
            hex"be1eace7000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000002004315d8f6f60c17543f768e33cb358539e390113bebdc8680c170b4658abd373c000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000067812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000000000089000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008737461726761746500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966692d617069000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000005ecbb340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000141de6dcf0a7b00000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe9200000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000001467812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        string memory bridge = "stargate";
        _decodeAndAssertTxData(bridge, stargateDataGeneratedOffChain, true, false, false);
    }

    function test_lifi_validator_realDataCelerCSR() public {
        bytes memory celerDataGeneratedOffChain =
            hex"482c6a850000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000014880000000000000000000000000000000000000000000000000000000010b50b20f624c1068793412de4836f0f5ca3f3df3d9023d76a06d0c3d1647a6a9eae0bd5000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000067812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000000005eed2660000000000000000000000000000000000000000000000000000000000000089000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007636272696467650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966692d617069000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d0000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000010438ed17390000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000005eed26600000000000000000000000000000000000000000000000000000000000000a00000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae0000000000000000000000000000000000000000000000000000000065a61fbc0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000000000000000000000000000000000000";
        string memory bridge = "cbridge";
        _decodeAndAssertTxData(bridge, celerDataGeneratedOffChain, true, true, false);
    }

    function test_lifi_validator_realDataAcrossCSR() public {
        bytes memory acrossDataGeneratedOffChain =
            hex"3a3f73320000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000006a00b98216784dbc29701b066446fdb578a6347ca30ed31d528b6db592d71c86e10000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000067812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000000005efb1da00000000000000000000000000000000000000000000000000000000000000890000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066163726f7373000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966692d6170690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000050f9bde1c76bba997a5d6e7fefff695ec8536194000000000000000000000000cb859ea579b28e02b87a1fde08d087ab9dbe5149000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000324301a3720000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000005efb1da000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000000000000000000000000000065a61fd0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000091e1c84ba8786b1fae2570202f0126c0b88f6ec70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c9f93163c99695c6526b799ebca2207fdf7d61ad000000000000000000000000000000000000000000000000000000000000000200000000000000000000000091e1c84ba8786b1fae2570202f0126c0b88f6ec700000000000000000000000050f9bde1c76bba997a5d6e7fefff695ec85361940000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3357e20b0c50000000000000000000000000000000000000000000000000000000065a60fa80000000000000000000000000000000000000000000000000000000000000080ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000d00dfeeddeadbeef8932eb23bad9bddb5cf81426f78279a53c6c3b71";
        string memory bridge = "across";
        _decodeAndAssertTxData(bridge, acrossDataGeneratedOffChain, true, true, false);
    }

    function test_lifi_validator_realDataAmarokCSR() public {
        bytes memory amarokDataGeneratedOffChain =
            hex"83f319170000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000006a09be4006c8ecc3f2d92cf88b0c5cc825c7eb1f84c577158fc549172a62650123c000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000067812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000000005efb1da0000000000000000000000000000000000000000000000000000000000000089000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006616d61726f6b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966692d6170690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000050f9bde1c76bba997a5d6e7fefff695ec8536194000000000000000000000000cb859ea579b28e02b87a1fde08d087ab9dbe5149000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000324301a3720000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000005efb1da000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000000000000000000000000000065a61fe9000000000000000000000000000000000000000000000000000000000000000100000000000000000000000091e1c84ba8786b1fae2570202f0126c0b88f6ec70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c9f93163c99695c6526b799ebca2207fdf7d61ad000000000000000000000000000000000000000000000000000000000000000200000000000000000000000091e1c84ba8786b1fae2570202f0126c0b88f6ec700000000000000000000000050f9bde1c76bba997a5d6e7fefff695ec853619400000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000067812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000066c3f4245af000000000000000000000000000000000000000000000000000000000000003200000000000000000000000067812f7490d0931da9f2a47cc402476b08f7850200000000000000000000000000000000000000000000000000000000706f6c7900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        string memory bridge = "amarok";
        _decodeAndAssertTxData(bridge, amarokDataGeneratedOffChain, true, true, false);
    }

    function test_lifi_validator_realDataHopCSR() public {
        bytes memory hopDataGeneratedOffChain =
            hex"42afe79a0000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e8dbd50000000000000000000000000000000000000000000000000000000065a763fc0000000000000000000000000000000000000000000000000000000005e8dbd50000000000000000000000000000000000000000000000000000000065a763fc0000000000000000000000003e4a3a4796d16c0cd582c382691998f7c06420b6000000000000000000000000a6a688f107851131f0e1dce493ebbebfaf99203e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000742117e1e29d2c76fc86d796df9ea140236356af63fec35f1c1099799028801d000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000067812f7490d0931da9f2a47cc402476b08f785020000000000000000000000000000000000000000000000000000000005efb1da0000000000000000000000000000000000000000000000000000000000000089000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003686f70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966692d6170690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000050f9bde1c76bba997a5d6e7fefff695ec8536194000000000000000000000000cb859ea579b28e02b87a1fde08d087ab9dbe5149000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000324301a3720000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000005efb1da000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000000000000000000000000000065a6208c000000000000000000000000000000000000000000000000000000000000000100000000000000000000000091e1c84ba8786b1fae2570202f0126c0b88f6ec70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c9f93163c99695c6526b799ebca2207fdf7d61ad000000000000000000000000000000000000000000000000000000000000000200000000000000000000000091e1c84ba8786b1fae2570202f0126c0b88f6ec700000000000000000000000050f9bde1c76bba997a5d6e7fefff695ec8536194000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        string memory bridge = "hop";
        _decodeAndAssertTxData(bridge, hopDataGeneratedOffChain, true, true, false);
    }

    function _decodeAndAssertTxData(
        string memory bridge_,
        bytes memory txData_,
        bool toCsr_,
        bool hasSourceSwaps_,
        bool hasDstCall_
    )
        internal
    {
        /// @dev deployed CSR
        address receiver =
            toCsr_ ? 0x67812f7490d0931dA9f2A47Cc402476B08f78502 : 0x377E5829f552cd3435538006e754e24fA304ABd4;
        /// @dev bridge token is USDC on ETH
        address token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        /// @dev validate the data
        (
            string memory bridge,
            address sendingAssetId,
            address receiverDecoded,
            uint256 amount,
            ,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        ) = LiFiValidator(getContract(ETH, "LiFiValidator")).extractMainParameters(txData_);

        assertEq(bridge, bridge_);
        assertEq(sendingAssetId, token);
        assertEq(receiverDecoded, receiver);
        assertEq(amount, 100_000_000);
        assertEq(destinationChainId, POLY);
        assertEq(hasSourceSwaps, hasSourceSwaps_);
        assertEq(hasDestinationCall, hasDstCall_);
    }

    function test_addRemoveFromBlacklist() public {
        vm.startPrank(deployer);

        LiFiValidator lifiValidator = LiFiValidator(getContract(ETH, "LiFiValidator"));
        lifiValidator.addToBlacklist(bytes4(keccak256("function3()")));
        assertTrue(lifiValidator.isSelectorBlacklisted(bytes4(keccak256("function3()"))));

        vm.expectRevert(Error.BLACKLISTED_SELECTOR.selector);
        lifiValidator.addToBlacklist(bytes4(keccak256("function3()")));

        lifiValidator.removeFromBlacklist(bytes4(keccak256("function3()")));
        assertFalse(lifiValidator.isSelectorBlacklisted(bytes4(keccak256("functio31()"))));

        vm.expectRevert(Error.NOT_BLACKLISTED_SELECTOR.selector);
        lifiValidator.removeFromBlacklist(bytes4(keccak256("function3()")));
    }

    function test_lifi_validator_validateReceiver_blacklistedSelector() public {
        vm.prank(deployer);
        LiFiValidator(getContract(ETH, "LiFiValidator")).addToBlacklist(bytes4(keccak256("blacklistedFunction()")));

        bytes memory txData = abi.encodeWithSignature("blacklistedFunction()");

        vm.expectRevert(Error.BLACKLISTED_SELECTOR.selector);
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateReceiver(txData, address(0));
    }

    function test_validate_receiver_genericLifiSwap() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "CoreStateRegistry"), true
            )
        );
        assertTrue(
            LiFiValidator(getContract(BSC, "LiFiValidator")).validateReceiver(
                txData, getContract(BSC, "CoreStateRegistry")
            )
        );
    }

    function test_lifi_validator_decodeAmountIn_blacklistedSelector() public {
        vm.prank(deployer);
        LiFiValidator(getContract(ETH, "LiFiValidator")).addToBlacklist(bytes4(keccak256("blacklistedFunction()")));

        bytes memory txData = abi.encodeWithSignature("blacklistedFunction()");

        vm.expectRevert(Error.BLACKLISTED_SELECTOR.selector);
        LiFiValidator(getContract(ETH, "LiFiValidator")).decodeAmountIn(txData, false);
    }

    function test_decodeAmountIn_invalidAction() public {
        // Build dummy txData with the swapTokensGeneric selector
        bytes memory txData = abi.encodeWithSelector(GenericSwapFacet.swapTokensGeneric.selector);

        vm.expectRevert(Error.INVALID_ACTION.selector);
        // Call decodeAmountIn with the dummy txData and genericSwapDisallowed set to true
        LiFiValidator(getContract(ETH, "LiFiValidator")).decodeAmountIn(txData, true);
    }

    function test_decodeDstSwap_zeroAddressToken() public {
        // Build dummy _swapData with token_ set to address(0)
        LibSwap.SwapData[] memory _swapData = new LibSwap.SwapData[](1);
        _swapData[0] = LibSwap.SwapData({
            callTo: address(1),
            approveTo: address(2),
            sendingAssetId: address(0),
            receivingAssetId: address(0),
            fromAmount: 100,
            callData: "",
            requiresDeposit: false
        });

        // Build dummy txData with the swapTokensGeneric selector and _swapData containing token_ set to address(0)
        bytes memory txData = abi.encodeWithSelector(
            GenericSwapFacet.swapTokensGeneric.selector,
            bytes32(0),
            "integrator",
            "referrer",
            address(this),
            100,
            _swapData
        );

        // Call decodeDstSwap with the dummy txData
        (address token, uint256 amount) = LiFiValidator(getContract(ETH, "LiFiValidator")).decodeDstSwap(txData);

        // Check that token_ is remapped to NATIVE
        assertEq(token, NATIVE);
        // Check that the amount is correct
        assertEq(amount, 100);
    }

    function test_decodeDstSwap_invalid_action() public {
        bytes memory txData = abi.encodeWithSignature("someFunc()");

        vm.expectRevert(Error.INVALID_ACTION.selector);
        LiFiValidator(getContract(ETH, "LiFiValidator")).decodeDstSwap(txData);
    }

    function test_decodeSwapOutputToken_invalid_action() public {
        bytes memory txData = abi.encodeWithSignature("someFunc()");

        vm.expectRevert(Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN.selector);
        LiFiValidator(getContract(ETH, "LiFiValidator")).decodeSwapOutputToken(txData);
    }

    function test_validateTxData_wrongChainIds_swapTokensGeneric() public {
        // Build dummy _swapData
        LibSwap.SwapData[] memory _swapData = new LibSwap.SwapData[](1);
        _swapData[0] = LibSwap.SwapData({
            callTo: address(1),
            approveTo: address(2),
            sendingAssetId: address(3),
            receivingAssetId: address(4),
            fromAmount: 100,
            callData: "",
            requiresDeposit: false
        });

        // Build dummy txData with the swapTokensGeneric selector and _swapData containing token_ set to address(0)
        bytes memory txData = abi.encodeWithSelector(
            GenericSwapFacet.swapTokensGeneric.selector,
            bytes32(0),
            "integrator",
            "referrer",
            address(this),
            100,
            _swapData
        );

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        // Call validateTxData with srcChainId equal to dstChainId
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData,
                ETH,
                BSC, // srcChainId is different than dstChainId
                ETH,
                true,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );

        vm.expectRevert(Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID.selector);
        // Call validateTxData with srcChainId equal to dstChainId
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData,
                ETH,
                ETH,
                BSC, // srcChainId is different than liqDstChainId
                true,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_invalidreceiver_swapTokensGeneric() public {
        // Build dummy _swapData
        LibSwap.SwapData[] memory _swapData = new LibSwap.SwapData[](1);
        _swapData[0] = LibSwap.SwapData({
            callTo: address(0),
            approveTo: address(2),
            sendingAssetId: address(3),
            receivingAssetId: address(4),
            fromAmount: 100,
            callData: "",
            requiresDeposit: false
        });

        // Build dummy txData with the swapTokensGeneric selector and _swapData containing token_ set to address(0)
        bytes memory txData = abi.encodeWithSelector(
            GenericSwapFacet.swapTokensGeneric.selector,
            bytes32(0),
            "integrator",
            "referrer",
            address(this),
            100,
            _swapData
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        // Call validateTxData with srcChainId equal to dstChainId
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData,
                ETH,
                ETH, // srcChainId is different than dstChainId
                ETH,
                true,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_invalidreceiver_swapTokensGeneric_withdraw() public {
        // Build dummy _swapData
        LibSwap.SwapData[] memory _swapData = new LibSwap.SwapData[](1);
        _swapData[0] = LibSwap.SwapData({
            callTo: deployer,
            approveTo: address(2),
            sendingAssetId: address(3),
            receivingAssetId: address(4),
            fromAmount: 100,
            callData: "",
            requiresDeposit: false
        });

        // Build dummy txData with the swapTokensGeneric selector and _swapData containing token_ set to address(0)
        bytes memory txData = abi.encodeWithSelector(
            GenericSwapFacet.swapTokensGeneric.selector,
            bytes32(0),
            "integrator",
            "referrer",
            address(this),
            100,
            _swapData
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        // Call validateTxData with srcChainId equal to dstChainId
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData,
                ETH,
                ETH, // srcChainId is different than dstChainId
                ETH,
                false,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_sendingAssetId_0() public {
        // Build dummy _swapData
        LibSwap.SwapData[] memory _swapData = new LibSwap.SwapData[](1);
        _swapData[0] = LibSwap.SwapData({
            callTo: deployer,
            approveTo: address(2),
            sendingAssetId: address(0),
            receivingAssetId: address(4),
            fromAmount: 100,
            callData: "",
            requiresDeposit: false
        });

        // Build dummy txData with the swapTokensGeneric selector and _swapData containing token_ set to address(0)
        bytes memory txData = abi.encodeWithSelector(
            GenericSwapFacet.swapTokensGeneric.selector, bytes32(0), "integrator", "referrer", deployer, 100, _swapData
        );

        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);
        // Call validateTxData with srcChainId equal to dstChainId
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData,
                ETH,
                ETH, // srcChainId is different than dstChainId
                ETH,
                false,
                address(0),
                deployer,
                address(0),
                NATIVE
            )
        );
    }

    function test_validateTxData_no_dstcall_allowed() public {
        // Build dummy _swapData
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData({
            callTo: deployer,
            approveTo: address(2),
            sendingAssetId: address(0),
            receivingAssetId: address(4),
            fromAmount: 100,
            callData: "",
            requiresDeposit: false
        });

        ILiFi.BridgeData memory bridgeData;

        bridgeData = ILiFi.BridgeData(
            bytes32("1"),
            /// request id
            "",
            "",
            address(0),
            address(0),
            address(0),
            100,
            uint256(ETH),
            false,
            true
        );
        bytes memory txData =
            abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);

        vm.expectRevert(Error.INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED.selector);
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ETH, ETH, false, address(0), deployer, address(0), NATIVE)
        );
    }
}
