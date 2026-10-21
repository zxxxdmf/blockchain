// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {DocumentVerification} from "../../src/pembanding/DocumentVerification.sol";

contract TokenUji is ERC721, AccessControl {
    bytes32 public constant PENERBIT = keccak256("PENERBIT");

    constructor() ERC721("Uji", "UJI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PENERBIT, msg.sender);
    }

    function terbitkan(address ke, uint256 id) external onlyRole(PENERBIT) {
        _mint(ke, id);
    }

    function supportsInterface(bytes4 i) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(i);
    }
}

contract RantaiTest is Test {
    function test_OpenZeppelinDanPembanding() public {
        TokenUji t = new TokenUji();
        t.terbitkan(address(0xBEEF), 1);
        assertEq(t.ownerOf(1), address(0xBEEF));

        DocumentVerification dv = new DocumentVerification();
        bytes32 h = keccak256("IJZ-FIKTIF-2026-001");
        dv.storeDocument(h, "cid-fiktif");
        assertTrue(dv.verifyDocument(h));
        assertFalse(dv.verifyDocument(keccak256("lain")));
    }
}
