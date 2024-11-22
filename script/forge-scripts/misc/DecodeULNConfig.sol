// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import "src/vendor/layerzero/v2/ILayerZeroEndpointV2.sol";

contract DecodeULNConfig is EnvironmentUtils {
    function decodeULNConfig(uint64 chainid, uint64 dstChainId, bytes memory config) public {
        _setEnvironment(0, false);
        _preDeploymentSetup();

        UlnConfig memory ulnConfig = abi.decode(config, (UlnConfig));

        address[] memory requiredDVNsToAssert = new address[](2);
        requiredDVNsToAssert[0] = SuperformDVNs[_getTrueIndex(chainid)];
        requiredDVNsToAssert[1] = LzDVNs[_getTrueIndex(chainid)];

        if (requiredDVNsToAssert[0] > requiredDVNsToAssert[1]) {
            (requiredDVNsToAssert[0], requiredDVNsToAssert[1]) = (requiredDVNsToAssert[1], requiredDVNsToAssert[0]);
        }
        assert(ulnConfig.confirmations == 0);
        assert(requiredDVNsToAssert[0] == ulnConfig.requiredDVNs[0]);
        assert(requiredDVNsToAssert[1] == ulnConfig.requiredDVNs[1]);
        console.log("asserted, SRC, DST: ", chainid, dstChainId);
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
