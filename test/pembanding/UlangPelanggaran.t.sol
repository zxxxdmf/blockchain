// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {DocumentVerification} from "src/pembanding/DocumentVerification.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";

contract UlangPelanggaranTest is Test {
    DocumentVerification dv;

    function setUp() public {
        dv = new DocumentVerification();
    }

    function test_templat_K3() public {
        bytes32 h = D.hashDokumen(0);
        vm.prank(makeAddr("pengguna1"));
        dv.storeDocument(h, "cid-fiktif-0");
        vm.prank(makeAddr("pengguna2"));
        vm.expectRevert(bytes("Dokumen sudah terdaftar"));
        dv.storeDocument(h, "cid-fiktif-1");
    }
}
