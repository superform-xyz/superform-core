/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Counters} from "openzeppelin-contracts//contracts/utils/Counters.sol";

contract KYCDaoNFTMock is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("KYCDaoNFT", "KYCDaoNFT") {}

    function mint(address owner) public returns (uint256) {
        _tokenIds.increment();

        uint256 newKycDAONFT = _tokenIds.current();
        _mint(owner, newKycDAONFT);

        return newKycDAONFT;
    }

    function hasValidToken(address _addr) public view returns (bool) {
        uint256 numTokens = balanceOf(_addr);
        if (numTokens > 0) return true;

        return false;
    }
}
