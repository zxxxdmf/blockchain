// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {DocumentVerification} from "src/pembanding/DocumentVerification.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";

/// @title Uji ulang pelanggaran kontrak pembanding tanpa handler (subbab 2.1, Tahap 6)
/// @notice Setiap urutan hasil shrinking yang melanggar K1 sampai K5 disalin ke sini sebagai satu unit test yang
///         memanggil DocumentVerification secara langsung. Pelanggaran hanya dilaporkan bila hasil yang sama muncul
///         kembali. Bila tidak muncul kembali, kesalahan ada pada handler: perbaiki handler, ulangi kampanye, dan
///         catat di catatan/LOG_PERUBAHAN.md.
///         Nama fungsi: test_ulang_<K>_s<seed>, contoh di bawah adalah templat (perilaku yang diklaim penulis).
contract UlangPelanggaranTest is Test {
    DocumentVerification dv;

    function setUp() public {
        dv = new DocumentVerification();
    }

    /// Templat: urutan panggilan disalin dari [Sequence] keluaran forge (pengirim, fungsi, argumen).
    function test_templat_K3() public {
        bytes32 h = D.hashDokumen(0);
        vm.prank(makeAddr("pengguna1"));
        dv.storeDocument(h, "cid-fiktif-0");
        vm.prank(makeAddr("pengguna2"));
        vm.expectRevert(bytes("Dokumen sudah terdaftar"));
        dv.storeDocument(h, "cid-fiktif-1");
    }
}
