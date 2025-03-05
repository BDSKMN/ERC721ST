// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SampleERC721ST} from "src/examples/SampleERC721ST.sol";

contract SampleERC721TTest is Test {
    SampleERC721ST sampleERC721ST;

    uint256 constant CURRENT_BLOCKTIMESTAMP = 1737667200; // January 23, 2025, 9:20 PM UTC

    address constant MINTER_OR_BURNER = 0xcfd86e16635486b2eCAf674A98F24ed12a15c3b4;
    address constant BAD_ACTOR = 0xac912225f59d840c700cc9F04CD5Ade96Bd009BF;
    address constant AIRDROP_RECIPIENT_INDEX_ZERO = 0xa74A9c716F60C7362a3909ca47E6362777C7EbcA;
    address constant AIRDROP_RECIPIENT_INDEX_ONE = 0x364D1F67f71d976A317F65cD64Ebc1E6C48a14AA;
    address constant AIRDROP_RECIPIENT_INDEX_TWO = 0x4754393f17E07ACB5984a5CFF8fa29c294c76FbC;

    address contractOwner;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event SubTierSet(
        uint256 indexed fromTokenId,
        uint256 indexed quantity,
        uint32 indexed tierId,
        uint24 subTierId,
        uint256 atTimestamp
    );
    event SubTierReset(uint256 indexed tokenId, uint32 indexed tierId, uint24 subTierId);

    error NotOwnerNorApproved();
    error TokenDoesNotExist();
    error Unauthorized();
    error TierCanNotBeZero();
    error SubTierCanNotBeZero();

    function setUp() external {
        sampleERC721ST = new SampleERC721ST();
        contractOwner = address(sampleERC721ST.owner());
    }

    /// Public view functions ///

    function test_Name() public view {
        assertEq(sampleERC721ST.name(),"Sample ERC721ST");
    }

    function test_Symbol() public view {
        assertEq(sampleERC721ST.symbol(), "S721ST");
    }

    function test_TokenURI() public {
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 1, 1); // _mintSubTier
        assertEq(sampleERC721ST.tokenURI(0),"ipfs://foobar/1/1/0"); // tokenId #0; tierId #1; subTierId #1
        sampleERC721ST.safeMintSubTier(MINTER_OR_BURNER, 2, 3); // _safeMintSubTier
        assertEq(sampleERC721ST.tokenURI(1),"ipfs://foobar/2/3/1"); // tokenId #1; tierId #2; subTierId #3
    }

    function test_TokenURI_ForNonExistentTokenId() public {
        vm.expectRevert(TokenDoesNotExist.selector);
        sampleERC721ST.tokenURI(0);
    }

    function test_SubTierId() public {
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 69, 420);

        (uint32 tierId, uint24 subTierId) = sampleERC721ST.subTierId(0);
        assertEq(tierId, 69);
        assertEq(subTierId, 420);
    }

    function test_SubTierId_ForNonExistentTokenId() public view {
        (uint32 tierId, uint24 subTierId) = sampleERC721ST.subTierId(0);
        assertEq(tierId, 0);
        assertEq(subTierId, 0);
    }

    function test_MintTimestamp() public {
        vm.warp(CURRENT_BLOCKTIMESTAMP);
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 69, 420);
        assertEq(sampleERC721ST.mintTimestamp(0), CURRENT_BLOCKTIMESTAMP);
    }

    function test_MintTimestamp_ForNonExistentTokenId() public view {
        assertEq(sampleERC721ST.mintTimestamp(0), 0);
    }

    function test_TotalMinted_AfterSingleTokenMinted() public {
        assertEq(sampleERC721ST.totalMinted(), 0); // Before mint
        _mintSubTierSingleToken();
        assertEq(sampleERC721ST.totalMinted(), 1); // After mint
    }

    function test_TotalMinted_AfterSingleTokenBurned() public {
        _mintSubTierSingleToken();
        assertEq(sampleERC721ST.totalMinted(), 1); // Before burn
        vm.prank(MINTER_OR_BURNER);
        sampleERC721ST.burnSubTierBy(MINTER_OR_BURNER, 0);
        assertEq(sampleERC721ST.totalMinted(), 1); // After burn
    }

    function test_TotalBurned_AfterSingleTokenMinted() public {
        assertEq(sampleERC721ST.totalBurned(), 0); // Before mint
        _mintSubTierSingleToken();
        assertEq(sampleERC721ST.totalBurned(), 0); // After mint
    }

    function test_TotalBurned_AfterSingleTokenBurned() public {
        _mintSubTierSingleToken();
        assertEq(sampleERC721ST.totalBurned(), 0); // Before burn
        vm.prank(MINTER_OR_BURNER);
        sampleERC721ST.burnSubTierBy(MINTER_OR_BURNER, 0);
        assertEq(sampleERC721ST.totalBurned(), 1); // After burn
    }

    function test_TotalSupply_AfterSingleTokenMinted() public {
        assertEq(sampleERC721ST.totalSupply(), 0); // Before mint
        _mintSubTierSingleToken();
        assertEq(sampleERC721ST.totalSupply(), 1); // After mint
    }

    function test_TotalSupply_AfterSingleTokenBurned() public {
        _mintSubTierSingleToken();
        assertEq(sampleERC721ST.totalSupply(), 1); // Before burn
        vm.prank(MINTER_OR_BURNER);
        sampleERC721ST.burnSubTierBy(MINTER_OR_BURNER, 0);
        assertEq(sampleERC721ST.totalSupply(), 0); // After burn
    }

    /// Mint functions ////

    function test_MintSubTier() public {
        vm.prank(MINTER_OR_BURNER);
        vm.warp(CURRENT_BLOCKTIMESTAMP);
        vm.expectEmit();
        emit Transfer(address(0), MINTER_OR_BURNER, 0); // Token ID starts from zero
        emit SubTierSet(0, 1, 1, 2, CURRENT_BLOCKTIMESTAMP);
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 1, 2);
    }

    function test_SafeMintSubTier() public {
        vm.warp(CURRENT_BLOCKTIMESTAMP);
        vm.prank(MINTER_OR_BURNER);
        vm.expectEmit();
        emit Transfer(address(0), MINTER_OR_BURNER, 0);
        emit SubTierSet(0, 1, 1, 3, CURRENT_BLOCKTIMESTAMP);
        sampleERC721ST.safeMintSubTier(MINTER_OR_BURNER, 1, 3);
    }

    function test_BatchMintSubTier() public {
        vm.warp(CURRENT_BLOCKTIMESTAMP);
        vm.prank(MINTER_OR_BURNER);
        vm.expectEmit();
        emit Transfer(address(0), MINTER_OR_BURNER, 0);
        emit Transfer(address(0), MINTER_OR_BURNER, 1);
        emit Transfer(address(0), MINTER_OR_BURNER, 2);
        emit SubTierSet(0, 3, 1, 2, CURRENT_BLOCKTIMESTAMP);
        sampleERC721ST.batchMintSubTier(MINTER_OR_BURNER, 1, 2, 3);
    }

    function test_BatchSafeMintSubTier() public {
        vm.warp(CURRENT_BLOCKTIMESTAMP);
        vm.prank(address(MINTER_OR_BURNER));
        vm.expectEmit();
        emit Transfer(address(0), MINTER_OR_BURNER, 0);
        emit Transfer(address(0), MINTER_OR_BURNER, 1);
        emit Transfer(address(0), MINTER_OR_BURNER, 2);
        emit SubTierSet(0, 3, 1, 2, CURRENT_BLOCKTIMESTAMP);
        sampleERC721ST.batchSafeMintSubTier(MINTER_OR_BURNER, 1, 2, 3);
    }

    function test_AirdropSubTier_ByContractOwner() public {
        address[] memory recipients = new address[](3);
        recipients[0] = AIRDROP_RECIPIENT_INDEX_ZERO;
        recipients[1] = AIRDROP_RECIPIENT_INDEX_ONE;
        recipients[2] = AIRDROP_RECIPIENT_INDEX_TWO;

        vm.warp(CURRENT_BLOCKTIMESTAMP);

        vm.prank(contractOwner);
        vm.expectEmit();
        emit Transfer(address(0), AIRDROP_RECIPIENT_INDEX_ZERO, 0);
        emit Transfer(address(0), AIRDROP_RECIPIENT_INDEX_ONE, 1);
        emit Transfer(address(0), AIRDROP_RECIPIENT_INDEX_TWO, 2);
        emit SubTierSet(0, 1, 1, 2, CURRENT_BLOCKTIMESTAMP);
        emit SubTierSet(1, 1, 1, 2, CURRENT_BLOCKTIMESTAMP);
        emit SubTierSet(2, 1, 1, 2, CURRENT_BLOCKTIMESTAMP);
        sampleERC721ST.airdropSubTier(recipients, 1, 2);
    }

    function test_RevertWhen_MintSubTier_TierIdIsZero() public {
        vm.prank(MINTER_OR_BURNER);
        vm.expectRevert(TierCanNotBeZero.selector);
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 0, 1);
    }

    function test_RevertWhen_MintSubTier_SubTierIdIsZero() public {
        vm.prank(MINTER_OR_BURNER);
        vm.expectRevert(SubTierCanNotBeZero.selector);
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 1, 0);
    }

    function test_RevertWhen_MintSubTier_BothTierIdAndSubTierIdAreZero() public {
        vm.prank(MINTER_OR_BURNER);
        vm.expectRevert(TierCanNotBeZero.selector);
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 0, 0);
    }

    function test_RevertWhen_MintSubTier_TierIdExceedsMaxUint32Value() public {
        vm.prank(MINTER_OR_BURNER);
        vm.expectRevert(); // panic: arithmetic underflow or overflow (0x11)
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, type(uint32).max + 1, 1);
    }

    function test_RevertWhen_MintSubTier_SubTierIdExceedsMaxUint24Value() public {
        vm.prank(MINTER_OR_BURNER);
        vm.expectRevert(); // panic: arithmetic underflow or overflow (0x11)
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 1, type(uint24).max + 1);
    }

    function test_RevertWhen_MintSubTier_BothTierIdAndSubTierIdExceedTheirMaxUintValue() public {
        vm.prank(MINTER_OR_BURNER);
        vm.expectRevert(); // panic: arithmetic underflow or overflow (0x11)
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, type(uint32).max + 1, type(uint24).max + 1);
    }
    
    function test_RevertWhen_AirdropSubTier_ByNonContractOwner() public {
        address[] memory recipients = new address[](3);
        recipients[0] = AIRDROP_RECIPIENT_INDEX_ZERO;
        recipients[1] = AIRDROP_RECIPIENT_INDEX_ONE;
        recipients[2] = AIRDROP_RECIPIENT_INDEX_TWO;

        vm.prank(BAD_ACTOR);
        vm.expectRevert(Unauthorized.selector);
        sampleERC721ST.airdropSubTier(recipients, 1, 2);
    }

    /// Burn functions ///

    function test_BurnSubTier_ByContractOwner() public {
        _mintSubTierSingleToken();
        
        vm.prank(contractOwner);
        vm.expectEmit();
        emit Transfer(MINTER_OR_BURNER, address(0), 0);
        emit SubTierReset(0, 1, 2);
        sampleERC721ST.burnSubTier(0);
    }

    function test_BurnSubTier_ByTokenOwner() public {
        _mintSubTierSingleToken();
        
        vm.prank(MINTER_OR_BURNER);
        vm.expectEmit();
        emit Transfer(MINTER_OR_BURNER, address(0), 0);
        emit SubTierReset(0, 1, 2);
        sampleERC721ST.burnSubTierBy(MINTER_OR_BURNER, 0);
    }

    function test_RevertWhen_BurnSubTier_ByNonTokenOwner() public {
        _mintSubTierSingleToken();
        
        vm.prank(BAD_ACTOR);
        vm.expectRevert(NotOwnerNorApproved.selector);
        sampleERC721ST.burnSubTierBy(BAD_ACTOR, 0);
    }

    function test_RevertWhen_BurnSubTier_ByNonContractOwner() public {
        _mintSubTierSingleToken();
        
        vm.prank(BAD_ACTOR);
        vm.expectRevert(Unauthorized.selector);
        sampleERC721ST.burnSubTier(0);
    }

    /// Internal setup ///

    function _mintSubTierSingleToken() internal {
        vm.prank(MINTER_OR_BURNER);
        sampleERC721ST.mintSubTier(MINTER_OR_BURNER, 1, 2);
    }
}