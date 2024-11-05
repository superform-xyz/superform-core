// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import "src/vendor/layerzero/v2/ILayerZeroEndpointV2.sol";

contract DecodeULNConfig is EnvironmentUtils {
    address[] public SuperformDVNs = [
        0x7518f30bd5867b5fA86702556245Dead173afE46,
        0xF4c489AfD83625F510947e63ff8F90dfEE0aE46C,
        0x8fb0B7D74B557e4b45EF89648BAc197EAb2E4325,
        0x1E4CE74ccf5498B19900649D9196e64BAb592451,
        0x5496d03d9065B08e5677E1c5D1107110Bb05d445,
        0xb0B2EF168F52F6d1e42f461e11117295eF992daf,
        0xEb62f578497Bdc351dD650853a751135212fAF49,
        0x2EdfE0220A74d9609c79711a65E3A2F2A85Dc83b,
        0x7A205ED4e3d7f9d0777594501705D8CD405c3B05,
        0x0E95cf21aD9376A26997c97f326C5A0a267bB8FF
    ];

    address[] public LzDVNs = [
        0x589dEDbD617e0CBcB916A9223F4d1300c294236b,
        0xfD6865c841c2d64565562fCc7e05e619A30615f0,
        0x962F502A63F5FBeB44DC9ab932122648E8352959,
        0x23DE2FE932d9043291f870324B74F820e11dc81A,
        0x2f55C492897526677C5B68fb199ea31E2c126416,
        0x6A02D83e8d433304bba74EF1c427913958187142,
        0x9e059a54699a285714207b43B055483E78FAac25,
        0xE60A3959Ca23a92BF5aAf992EF837cA7F828628a,
        0x129Ee430Cb2Ff2708CCADDBDb408a88Fe4FFd480,
        0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f
    ];

    struct UlnConfig {
        uint64 confirmations;
        // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
        uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
        uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
        uint8 optionalDVNThreshold; // (0, optionalDVNCount]
        address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
        address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
    }

    function decodeULNConfig(uint64 chainid, uint64 dstChainId, bytes memory config) public {
        _setEnvironment(0, false);
        _preDeploymentSetup();

        UlnConfig memory ulnConfig = abi.decode(config, (UlnConfig));

        assert(CONFIRMATIONS[chainid][dstChainId] == ulnConfig.confirmations);

        address[] memory requiredDVNsToAssert = new address[](2);
        requiredDVNsToAssert[0] = SuperformDVNs[_getTrueIndex(chainid)];
        requiredDVNsToAssert[1] = LzDVNs[_getTrueIndex(chainid)];

        if (requiredDVNsToAssert[0] > requiredDVNsToAssert[1]) {
            (requiredDVNsToAssert[0], requiredDVNsToAssert[1]) = (requiredDVNsToAssert[1], requiredDVNsToAssert[0]);
        }

        assert(requiredDVNsToAssert[0] == ulnConfig.requiredDVNs[0]);
        assert(requiredDVNsToAssert[1] == ulnConfig.requiredDVNs[1]);
        console.log("asserted, SRC, DST, Confirmations: ", chainid, dstChainId, ulnConfig.confirmations);
    }

    function _getTrueIndex(uint256 chainId) public view returns (uint256 index) {
        for (uint256 i; i < chainIds.length; i++) {
            if (chainId == chainIds[i]) {
                index = i;
                break;
            }
        }
    }
}
