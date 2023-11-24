// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

interface IKycValidity {
    /// @dev Check whether a given address has a valid kycNFT token
    /// @param _addr Address to check for tokens
    /// @return valid Whether the address has a valid token
    function hasValidToken(address _addr) external view returns (bool valid);
}
