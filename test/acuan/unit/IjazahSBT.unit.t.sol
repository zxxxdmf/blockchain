// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {IjazahSBT} from "src/IjazahSBT.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";

contract IjazahSBTUnitTest is Test {
    IjazahSBT ijazah;
    address admin = makeAddr("admin");
    address penerbit = makeAddr("penerbit");
    address pemegang = makeAddr("pemegang");
    address penyerang = makeAddr("penyerang");

    function setUp() public {
        ijazah = new IjazahSBT();
        ijazah.inisialisasi(admin);
        vm.prank(admin);
        ijazah.tetapkanPenerbit(penerbit);
    }

    function _terbitkan(uint256 k) internal returns (uint256 id) {
        vm.prank(penerbit);
        id = ijazah.terbitkan(pemegang, D.hashNomor(k), D.hashDokumen(k));
    }

    function _cabut(uint256 id) internal {
        vm.prank(penerbit);
        ijazah.cabut(id);
    }

    function test_terbitkan_B() public {
        uint256 id = _terbitkan(0);
        assertEq(ijazah.ownerOf(id), pemegang);
        (bytes32 hn, bytes32 hd, bool dicabut) = ijazah.dataToken(id);
        assertEq(hn, D.hashNomor(0));
        assertEq(hd, D.hashDokumen(0));
        assertFalse(dicabut);
    }

    function test_terbitkan_V() public {
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.HashKosong.selector);
        ijazah.terbitkan(pemegang, bytes32(0), D.hashDokumen(0));
    }

    function test_terbitkan_G() public {
        _terbitkan(0);
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.DataGanda.selector);
        ijazah.terbitkan(pemegang, D.hashNomor(0), D.hashDokumen(1));
    }

    function test_terbitkan_P() public {
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.BukanPenerbit.selector);
        ijazah.terbitkan(penyerang, D.hashNomor(0), D.hashDokumen(0));
    }

    function test_terbitkanUlang_B() public {
        uint256 lama = _terbitkan(0);
        _cabut(lama);
        vm.prank(penerbit);
        uint256 baru = ijazah.terbitkanUlang(lama, pemegang, D.hashDokumenPengganti(0, 1));
        assertEq(ijazah.ownerOf(baru), pemegang);
        (bytes32 hn, bytes32 hd, bool dicabut) = ijazah.dataToken(baru);
        assertEq(hn, D.hashNomor(0));
        assertEq(hd, D.hashDokumenPengganti(0, 1));
        assertFalse(dicabut);
    }

    function test_terbitkanUlang_V() public {
        uint256 lama = _terbitkan(0);
        _cabut(lama);
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.HashKosong.selector);
        ijazah.terbitkanUlang(lama, pemegang, bytes32(0));
    }

    function test_terbitkanUlang_G() public {
        uint256 lama = _terbitkan(0);
        _cabut(lama);
        vm.prank(penerbit);
        ijazah.terbitkanUlang(lama, pemegang, D.hashDokumenPengganti(0, 1));
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.MasihAdaTokenAktif.selector);
        ijazah.terbitkanUlang(lama, pemegang, D.hashDokumenPengganti(0, 2));
    }

    function test_terbitkanUlang_T() public {
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.TokenTidakAda.selector);
        ijazah.terbitkanUlang(99, pemegang, D.hashDokumenPengganti(0, 1));
    }

    function test_terbitkanUlang_P() public {
        uint256 lama = _terbitkan(0);
        _cabut(lama);
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.BukanPenerbit.selector);
        ijazah.terbitkanUlang(lama, penyerang, D.hashDokumenPengganti(0, 1));
    }

    function test_cabut_B() public {
        uint256 id = _terbitkan(0);
        _cabut(id);
        (,, bool dicabut) = ijazah.dataToken(id);
        assertTrue(dicabut);
    }

    function test_cabut_G() public {
        uint256 id = _terbitkan(0);
        _cabut(id);
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.SudahDicabut.selector);
        ijazah.cabut(id);
    }

    function test_cabut_T() public {
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.TokenTidakAda.selector);
        ijazah.cabut(99);
    }

    function test_cabut_P() public {
        uint256 id = _terbitkan(0);
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.BukanPenerbit.selector);
        ijazah.cabut(id);
    }

    function test_transfer_B() public {
        uint256 id = _terbitkan(0);
        assertTrue(ijazah.locked(id));
        vm.prank(pemegang);
        vm.expectRevert(IjazahSBT.TokenTerkunci.selector);
        ijazah.transferFrom(pemegang, makeAddr("lain"), id);
    }

    function test_transfer_V() public {
        uint256 id = _terbitkan(0);
        vm.prank(pemegang);
        vm.expectRevert();
        ijazah.transferFrom(pemegang, address(0), id);
    }

    function test_transfer_T() public {
        vm.prank(pemegang);
        vm.expectRevert();
        ijazah.transferFrom(pemegang, makeAddr("lain"), 99);
    }

    function test_transfer_P() public {
        uint256 id = _terbitkan(0);
        vm.prank(penyerang);
        vm.expectRevert();
        ijazah.transferFrom(pemegang, penyerang, id);
    }

    function test_inisialisasi_B() public {
        IjazahSBT baru = new IjazahSBT();
        baru.inisialisasi(admin);
        assertTrue(baru.hasRole(baru.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_inisialisasi_V() public {
        IjazahSBT baru = new IjazahSBT();
        vm.expectRevert(IjazahSBT.AlamatNol.selector);
        baru.inisialisasi(address(0));
    }

    function test_inisialisasi_G() public {
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.SudahDiinisialisasi.selector);
        ijazah.inisialisasi(penyerang);
    }

    function test_gantiAdmin_B() public {
        address adminBaru = makeAddr("adminBaru");
        vm.prank(admin);
        ijazah.gantiAdmin(adminBaru);
        assertTrue(ijazah.hasRole(ijazah.DEFAULT_ADMIN_ROLE(), adminBaru));
        assertFalse(ijazah.hasRole(ijazah.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_gantiAdmin_V() public {
        vm.prank(admin);
        vm.expectRevert(IjazahSBT.AlamatNol.selector);
        ijazah.gantiAdmin(address(0));
    }

    function test_gantiAdmin_P() public {
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.BukanAdmin.selector);
        ijazah.gantiAdmin(penyerang);
    }

    function test_tetapkanPenerbit_B() public {
        address p2 = makeAddr("penerbit2");
        vm.prank(admin);
        ijazah.tetapkanPenerbit(p2);
        assertTrue(ijazah.hasRole(ijazah.PENERBIT(), p2));
    }

    function test_tetapkanPenerbit_V() public {
        vm.prank(admin);
        vm.expectRevert(IjazahSBT.AlamatNol.selector);
        ijazah.tetapkanPenerbit(address(0));
    }

    function test_tetapkanPenerbit_P() public {
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.BukanAdmin.selector);
        ijazah.tetapkanPenerbit(penyerang);
    }

    function test_hapusPenerbit_B() public {
        vm.prank(admin);
        ijazah.hapusPenerbit(penerbit);
        assertFalse(ijazah.hasRole(ijazah.PENERBIT(), penerbit));
    }

    function test_hapusPenerbit_T() public {
        address bukan = makeAddr("bukanPenerbit");
        vm.prank(admin);
        ijazah.hapusPenerbit(bukan);
        assertFalse(ijazah.hasRole(ijazah.PENERBIT(), bukan));
        assertTrue(ijazah.hasRole(ijazah.PENERBIT(), penerbit));
    }

    function test_hapusPenerbit_P() public {
        vm.prank(penyerang);
        vm.expectRevert(IjazahSBT.BukanAdmin.selector);
        ijazah.hapusPenerbit(penerbit);
    }

    function test_renounceRole_P() public {
        bytes32 peran = ijazah.PENERBIT();
        vm.prank(penerbit);
        vm.expectRevert(IjazahSBT.FungsiDinonaktifkan.selector);
        ijazah.renounceRole(peran, penerbit);
    }

    function test_verifikasi_B() public {
        uint256 id = _terbitkan(0);
        assertEq(uint256(ijazah.verifikasi(id, D.hashNomor(0))), uint256(IjazahSBT.Hasil.Aktif));
    }

    function test_verifikasi_V() public {
        uint256 id = _terbitkan(0);
        assertEq(uint256(ijazah.verifikasi(id, D.hashNomor(1))), uint256(IjazahSBT.Hasil.TidakCocok));
    }

    function test_verifikasi_T() public view {
        assertEq(uint256(ijazah.verifikasi(99, D.hashNomor(0))), uint256(IjazahSBT.Hasil.TidakTerdaftar));
    }
}
