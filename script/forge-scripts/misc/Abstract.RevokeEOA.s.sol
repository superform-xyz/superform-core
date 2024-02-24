// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../Abstract.Deploy.Single.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address paymentHelper;
    address superRegistry;
    SuperRegistry superRegistryC;
}

abstract contract AbstractRevokeEOA is AbstractDeploySingle {
    /// @dev Revoke roles
    function _revokeEOAs(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        SuperRBAC srbac = SuperRBAC(payable(_readContract(chainNames[trueIndex], vars.chainId, "SuperRBAC")));
        bytes32 protocolAdminRole = srbac.PROTOCOL_ADMIN_ROLE();
        bytes32 emergencyAdminRole = srbac.EMERGENCY_ADMIN_ROLE();

        srbac.revokeRole(emergencyAdminRole, ownerAddress);
        srbac.revokeRole(protocolAdminRole, ownerAddress);

        vm.stopBroadcast();
    }
}
