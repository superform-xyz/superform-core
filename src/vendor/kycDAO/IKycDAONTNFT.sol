// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title A standard interface for checking and updating the expiry and validity of KYC Non-transferable NFTs
 */
interface IKycdaoNTNFT {
    /// SOLE FUNCTION USED BY IMPLEMENTERS

    /// @dev Check whether a given address has ANY token which is valid,
    ///      i.e. is verified and has an expiry in the future
    /// @param _addr Address to check for tokens
    /// @return valid Whether the address has a valid token
    function hasValidToken(address _addr) external view returns (bool valid);

    /// MINTING

    /// @dev Authorize the minting of a new token
    /// @param _auth_code The auth code used to authorize the mint
    /// @param _dst Address to mint the token to
    /// @param _metadata_cid The metadata CID for the token
    /// @param _expiry The time, in secs since epoch, at which to set the token's expiry on mint
    /// @param _seconds_to_pay The number of seconds of subscription time that need to be paid for when the token is
    /// minted
    /// @param _verification_tier The verification tier of the token
    function authorizeMintWithCode(
        uint32 _auth_code,
        address _dst,
        string calldata _metadata_cid,
        uint256 _expiry,
        uint32 _seconds_to_pay,
        string calldata _verification_tier
    )
        external;

    /// @dev Mint the token by using an authorization code from an authorized account
    /// @param _auth_code The auth code used to authorize the mint
    function mintWithCode(uint32 _auth_code) external payable;

    /// @dev Returns the amount in NATIVE (wei) which is expected for a given mint which uses an auth code
    /// @param _auth_code The auth code used to authorize the mint
    /// @param _dst Address to mint the token to
    function getRequiredMintCostForCode(uint32 _auth_code, address _dst) external view returns (uint256);

    /// @dev Returns the cost for subscription per year in USD, to SUBSCRIPTION_COST_DECIMALS decimal places
    function getSubscriptionCostPerYearUSD() external view returns (uint256);

    /// (TO BE IMPLEMENTED)
    //TODO: Will look at minting with signatures in a future release
    /// @dev Mint the token using a signature to verify authorization
    /// @param _auth_code The auth code used to authorize the mint
    /// @param _metadata_cid The metadata CID for the token
    /// @param _expiry The time, in secs since epoch, at which to set the token's expiry on mint
    /// @param _seconds_to_pay The number of seconds of subscription time that need to be paid for when the token is
    /// minted
    /// @param _verification_tier The verification tier of the token
    /// @param _signature The signature by the minting authority for this mint
    function mintWithSignature(
        uint32 _auth_code,
        string memory _metadata_cid,
        uint256 _expiry,
        uint32 _seconds_to_pay,
        string calldata _verification_tier,
        bytes calldata _signature
    )
        external
        payable;

    /// @dev Returns the amount in NATIVE (wei) which is expected for a given amount of subscription time in seconds
    /// @param _seconds The number of seconds of subscription time to calculate the cost for
    function getRequiredMintCostForSeconds(uint32 _seconds) external view returns (uint256);

    /// CHECK TOKEN STATUS

    /// @dev Get the current expiry of a specific token in secs since epoch
    /// @param _tokenId ID of the token to query
    /// @return expiry The expiry of the given token in secs since epoch
    function tokenExpiry(uint256 _tokenId) external view returns (uint256 expiry);

    /// @dev Get the verification tier of a specific token
    /// @param _tokenId ID of the token to query
    /// @return tier The tier of the given token
    function tokenTier(uint256 _tokenId) external view returns (string memory tier);

    /// UPDATE STATUS

    /// @dev Set whether a token is verified or not
    /// @param _tokenId ID of the token
    /// @param _verified A bool indicating whether this token is verified
    function setVerifiedToken(uint256 _tokenId, bool _verified) external;

    /// @dev Update the given token to a new expiry
    /// @param _tokenId ID of the token whose expiry should be updated
    /// @param _expiry New expiry date for the token in secs since epoch
    function updateExpiry(uint256 _tokenId, uint256 _expiry) external;
}
