// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721ST} from "src/ERC721ST.sol";
import {Ownable} from "lib/solady/src/auth/Ownable.sol";

contract SampleERC721ST is ERC721ST, Ownable {

    constructor() ERC721ST("Sample ERC721ST", "S721ST") {
        _initializeOwner(msg.sender);
    }

    function mintSubTier(address to, uint32 tierId, uint24 subTierId) public {
        _mintSubTier(to, tierId, subTierId);
    }

    function safeMintSubTier(address to, uint32 tierId, uint24 subTierId) public {
        _safeMintSubTier(to, tierId, subTierId);
    }

    function batchMintSubTier(address to, uint32 tierId, uint24 subTierId, uint256 quantity) public {
        _batchMintSubTier(to, tierId, subTierId, quantity);
    }

    function batchSafeMintSubTier(address to, uint32 tierId, uint24 subTierId, uint256 quantity) public {
        _batchSafeMintSubTier(to, tierId, subTierId, quantity);
    }

    function airdropSubTier(
        address[] calldata recipients,
        uint32 tierId,
        uint24 subTierId
    ) public onlyOwner {
        for (uint256 i = 0; i < recipients.length;) {
            _mintSubTier(recipients[i], tierId, subTierId);
            unchecked { ++i; }   
        }
    }

    function burnSubTier(uint256 tokenId) public onlyOwner {
        _burnSubTier(tokenId);
    }

    function burnSubTierBy(address owner, uint256 tokenId) public {
        _burnSubTier(owner, tokenId);
    }

    function _baseSubTierURI() internal view virtual override returns (string memory) {
        return 'ipfs://foobar/';
    }
}