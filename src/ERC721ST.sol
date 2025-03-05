// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "lib/solady/src/tokens/ERC721.sol";

/// @title ERC721-ST
/// @author 0xkuwabatake (@0xkuwabatake)
/// @notice Abstract ERC721 contract with sub tier-based structure and sequential minting, 
///         using extra data packing for efficiency.
/// @dev    Extends Solady's ERC721 and modifies it to support sequential minting 
///         while mapping tokens to tiers and their sub-tiers via bitwise operations.
abstract contract ERC721ST is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Bit position for tier ID in extra data.
    uint96 private constant _BITPOS_TIER_ID = 32;

    /// @dev Bit position for sub-tier ID in extra data.
    uint96 private constant _BITPOS_SUB_TIER_ID = 56;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Tracks the next token ID to be minted.
    uint256 private _currentIndex;

    /// @dev Tracks the number of burned tokens.
    uint256 internal _burnCounter;

    /// @dev Name of the token collection.
    string private _name;

    /// @dev Symbol of the token collection.
    string private _symbol;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when from token with quantity is set to a tier and sub-tier.
    event SubTierSet(
        uint256 indexed fromTokenId,
        uint256 indexed quantity,
        uint32 indexed tierId,
        uint24 subTierId,
        uint40 atTimestamp
    );

    /// @dev Emitted when a token's tier and sub-tier are reset (burned).
    event SubTierReset(uint256 indexed tokenId, uint32 indexed tierId, uint24 subTierId);

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Reverts if the tier ID is zero.
    error TierCanNotBeZero();

    /// @dev Reverts if the sub-tier ID is zero.
    error SubTierCanNotBeZero();

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    /// @dev Ensures the tier ID and sub-tier ID are not zero.
    modifier TierAndSubTierAreNotZero(uint32 tier, uint24 subTier) {
        _requireTierAndSubTierAreNotZero(tier, subTier);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 METADATA
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the token collection name.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @dev Returns the token URI for a given token ID.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _rv(uint32(TokenDoesNotExist.selector));

        string memory baseSubTierURI = _baseSubTierURI();
        (uint32 tier, uint24 subTier) = subTierId(tokenId);
        
        return bytes(baseSubTierURI).length != 0
            ? string(
                  abi.encodePacked(
                      baseSubTierURI,
                      _toString(uint256(tier)),
                      '/',
                      _toString(uint256(subTier)),
                      '/',
                      _toString(tokenId)
                  )
              ) 
            : ''
        ;
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the tier ID and sub-tier ID associated with a token.
    function subTierId(uint256 tokenId) 
        public
        view
        returns (uint32 tier, uint24 subTier)
    {
        tier = uint32(_getExtraData(tokenId));
        subTier = uint24(_getExtraData(tokenId) >> _BITPOS_TIER_ID);
    }

    /// @dev Returns the timestamp when the token was minted.
    function mintTimestamp(uint256 tokenId) public view returns (uint40) {
        return uint40(_getExtraData(tokenId) >> _BITPOS_SUB_TIER_ID);
    }

    /// @dev Returns the total minted of tokens in circulation.
    function totalMinted() public view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /// @dev Returns the total burned of tokens in circulation.
    function totalBurned() public view returns (uint256) {
        return _burnCounter;
    }

    /// @dev Returns the total supply of tokens in circulation.
    function totalSupply() public view returns (uint256) {
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL MINT & BURN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Mints a token and assigns it a tier and sub-tier.
    function _mintSubTier(
        address to,
        uint32 tier,
        uint24 subTier
    ) internal TierAndSubTierAreNotZero(tier, subTier) {
        uint256 tokenId = _nextTokenId();
        unchecked { ++_currentIndex; }
        _mint(to, tokenId);
        _setMintExtraData(tokenId, tier, subTier);
        emit SubTierSet(tokenId, 1, tier, subTier, uint40(block.timestamp));
    }

    /// @dev Safely mints a token and assigns it a tier and sub-tier
    function _safeMintSubTier(
        address to,
        uint32 tier,
        uint24 subTier
    ) internal TierAndSubTierAreNotZero(tier, subTier) {
        uint256 tokenId = _nextTokenId();
        unchecked { ++_currentIndex; }
        _safeMint(to, tokenId);
        _setMintExtraData(tokenId, tier, subTier);
        emit SubTierSet(tokenId, 1, tier, subTier, uint40(block.timestamp));
    }

    /// @dev Mints multiple tokens with the same tier and sub-tier in a single batch.
    function _batchMintSubTier(
        address to,
        uint32 tier,
        uint24 subTier,
        uint256 quantity
    ) internal TierAndSubTierAreNotZero(tier, subTier) {
        uint256 fromTokenId = _nextTokenId();

        unchecked {
            _currentIndex += quantity;

            uint256 i;
            do {
                _mint(to, fromTokenId + i);
                _setMintExtraData(fromTokenId + i, tier, subTier);
                ++i;
            } while (i != quantity);
        
            emit SubTierSet(fromTokenId, quantity, tier, subTier, uint40(block.timestamp));
        }
    }

    /// @dev Safely mints multiple tokens with the same tier and sub-tier in a single batch.
    function _batchSafeMintSubTier(
        address to,
        uint32 tier,
        uint24 subTier,
        uint256 quantity
    ) internal TierAndSubTierAreNotZero(tier, subTier) {
        uint256 fromTokenId = _nextTokenId();

        unchecked {
            _currentIndex += quantity;

            uint256 i;
            do {
                _safeMint(to, fromTokenId + i);
                _setMintExtraData(fromTokenId + i, tier, subTier);
                ++i;
            } while (i != quantity);
        
            emit SubTierSet(fromTokenId, quantity, tier, subTier, uint40(block.timestamp));
        }
    }

    /// @dev Burns a token and resets its tier and sub-tier data.
    function _burnSubTier(uint256 tokenId) internal {
        (uint32 tier, uint24 subTier) = subTierId(tokenId);
        unchecked { ++_burnCounter; }
        _resetMintExtraData(tokenId);
        _burn(tokenId);
        emit SubTierReset(tokenId, tier, subTier);
    }

    /// @dev Burns a token on behalf of an address and resets its tier and sub-tier data.
    function _burnSubTier(address by, uint256 tokenId) internal {
        (uint32 tier, uint24 subTier) = subTierId(tokenId);
        unchecked { ++_burnCounter; }
        _resetMintExtraData(tokenId);
        _burn(by, tokenId);
        emit SubTierReset(tokenId, tier, subTier);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets the extra data for a token to store tier, sub-tier, and timestamp.
    function _setMintExtraData(uint256 tokenId, uint32 tier, uint24 subTier) internal {
        uint96 packed = uint96(tier)
            | uint96(subTier) << _BITPOS_TIER_ID
            | uint96(uint40(block.timestamp)) << _BITPOS_SUB_TIER_ID; 
        _setExtraData(tokenId, packed);
    }

    /// @dev Resets the extra data of a token.
    function _resetMintExtraData(uint256 tokenId) internal {
        _setExtraData(tokenId, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the starting token ID. 
    /// Note: Override this function to change the starting token ID.
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /// @dev Returns the next token ID to be minted.
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /// @dev @dev Base sub-tier URI for computing {tokenURI}.
    /// Note: If set, the resulting URI for each token will be the concatenation of the `baseSubTierURI`,
    /// `tierId`, `subTierId`, and the `tokenId`. Empty by default, it can be overridden in child contracts.
    function _baseSubTierURI() internal view virtual returns (string memory) {
        return '';
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Reverts if the tier ID and sub-tier ID are zero.
    function _requireTierAndSubTierAreNotZero(uint32 tier, uint24 subTier) internal pure {
        if (tier == 0) _rv(uint32(TierCanNotBeZero.selector));
        if (subTier == 0) _rv(uint32(SubTierCanNotBeZero.selector));
    }

    /// @dev Converts a uint256 value to a string.
    function _toString(uint256 value) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := add(mload(0x40), 0x80)
            mstore(0x40, add(result, 0x20))
            mstore(result, 0)
            let end := result
            let w := not(0)
            for { let temp := value } 1 {} {
                result := add(result, w)
                mstore8(result, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(end, result)
            result := sub(result, 0x20)
            mstore(result, n)
        }
    }

    /// @dev Efficient way to revert with a specific error code.
    function _rv(uint32 s) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, s)
            revert(0x1c, 0x04)
        }
    }
}