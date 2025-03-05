# ERC721T

## About
ERC721T extends [Solady’s ERC721](https://github.com/Vectorized/solady/blob/main/src/tokens/ERC721.sol) by leveraging the 96-bit extra data (via [`_setExtraData`](https://github.com/Vectorized/solady/blob/main/src/tokens/ERC721.sol#L424)) to map token IDs to tier IDs and sub-tier IDs, enabling tier-based NFT collections (with sub-categories) and efficient on-chain storage. 

If you only need tier functionality (without sub-tiers), check out [ERC721T](https://github.com/0xkuwabatake/ERC721T).

## Use Cases
1. Tier-Based Membership NFTs
    - Each membership tier (e.g., “VIP”) can have sub-categories (e.g., “VIP A,” “VIP B”).
2. Ticketing Systems
    - Assign event tiers (e.g., “General,” “Premium”) and sub-tiers (e.g., “General Day 1,” “Premium Day 1”).
3. Dynamic Rarity Collections
    - Handle main rarity tiers (e.g., “Limited Edition,” “Open Edition”) with sub-tier variations.
4. POAPs with Multiple Categories
    - Each badge can belong to a higher-level tier (like “Regional Event”) and a sub-tier (like “North Region”).

## How It Works
1.	Tier ID and its sub-Tier ID are assigned on mint, stored via extra data in Solady’s ERC721.
	  - Tier ID and Sub-Tier ID cannot be zero, as zero is the default value for non-minted tokens.
	  - When a token is burned, its tier ID and sub-tier ID resets to zero, ensuring no ambiguity in existence.
2.	Minting follows a sequential ID model, which is ideal for NFT collections, maintaining a structured token distribution.
3.	Supports batch minting, allowing multiple tokens to be assigned the same Tier ID in one transaction.

## Example Implementation
Check out the [SampleERC721ST](https://github.com/0xkuwabatake/ERC721ST/blob/main/src/examples/SampleERC721ST.sol) contract as a sample for practical implementation.

## Disclaimer

This contract is unaudited and provided as is, without warranties. Use at your own risk. Always conduct thorough testing before deploying in production.