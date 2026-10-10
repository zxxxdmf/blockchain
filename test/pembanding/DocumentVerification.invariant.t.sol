// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {DocumentVerification} from "src/pembanding/DocumentVerification.sol";
import {HandlerPembanding} from "test/pembanding/HandlerPembanding.sol";

/// @title Invariant K1 sampai K5 kontrak pembanding (Tabel 2.2)
/// @notice Dirumuskan dari klaim dan skenario uji Bimantoro et al. (2026). Kontrak pembanding tidak memiliki versi
///         yang dijamin benar, sehingga setiap pelanggaran dijalankan ulang langsung ke kontrak tanpa handler
///         (UlangPelanggaran.t.sol) dan hanya dilaporkan bila hasil yang sama muncul kembali.
contract DocumentVerificationInvariantTest is Test {
    DocumentVerification dv;
    HandlerPembanding handler;

    function setUp() public {
        dv = new DocumentVerification();
        handler = new HandlerPembanding(dv);
        targetContract(address(handler));
        bytes4[] memory s = new bytes4[](2);
        s[0] = HandlerPembanding.storeDocument.selector;
        s[1] = HandlerPembanding.majukanWaktu.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: s}));
    }

    /// K1: pendaftaran dengan hash kosong selalu ditolak.
    function invariant_K1() public view {
        assertEq(handler.diterimaHashKosong(), 0, "K1: pendaftaran dengan hash kosong diterima");
    }

    /// K2: pendaftaran dengan CID kosong selalu ditolak.
    function invariant_K2() public view {
        assertEq(handler.diterimaCidKosong(), 0, "K2: pendaftaran dengan CID kosong diterima");
    }

    /// K3: hash yang sudah terdaftar tidak dapat didaftarkan lagi oleh alamat mana pun.
    function invariant_K3() public view {
        assertEq(handler.diterimaGanda(), 0, "K3: hash yang sudah terdaftar didaftarkan lagi");
    }

    /// K4: data dokumen yang sudah tersimpan (CID, alamat pendaftar, waktu pendaftaran) tidak pernah berubah.
    function invariant_K4() public view {
        for (uint256 i; i < handler.JUMLAH_HASH(); ++i) {
            bytes32 h = handler.hashKe(i);
            (bool diterima, string memory cid, address pendaftar, uint256 waktu) = handler.catatan(h);
            if (!diterima) continue;
            (string memory cidK, address pendaftarK, uint256 waktuK) = dv.getDocument(h);
            assertEq(cidK, cid, "K4: CID berubah");
            assertEq(pendaftarK, pendaftar, "K4: alamat pendaftar berubah");
            assertEq(waktuK, waktu, "K4: waktu pendaftaran berubah");
        }
    }

    /// K5: verifyDocument bernilai benar untuk hash yang pernah diterima dan salah untuk hash lainnya.
    function invariant_K5() public view {
        for (uint256 i; i < handler.JUMLAH_HASH(); ++i) {
            bytes32 h = handler.hashKe(i);
            (bool diterima,,,) = handler.catatan(h);
            assertEq(dv.verifyDocument(h), diterima, "K5: hasil verifyDocument berbeda dari daftar hash yang tercatat");
        }
    }
}
