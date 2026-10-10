// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {DocumentVerification} from "src/pembanding/DocumentVerification.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";

/// @title Handler kontrak pembanding (subbab 2.1, Tabel 2.2)
/// @notice Nilai acak forge dipetakan ke tiga alamat tanpa peran, ke sepuluh hash dokumen sintetis ditambah hash
///         kosong, dan ke CID fiktif ditambah CID kosong. Variabel bayangan mencatat hash yang sudah diterima
///         beserta CID, pendaftar, dan waktunya, serta menghitung pendaftaran yang seharusnya ditolak tetapi
///         diterima kontrak.
contract HandlerPembanding is Test {
    DocumentVerification public immutable dv;
    address[3] public aktor;
    uint256 public constant JUMLAH_HASH = D.JUMLAH + 1; // sepuluh hash dokumen + hash kosong

    struct Catatan {
        bool diterima;
        string cid;
        address pendaftar;
        uint256 waktu;
    }

    mapping(bytes32 => Catatan) internal _catatan;
    uint256 public diterimaHashKosong; // K1
    uint256 public diterimaCidKosong; // K2
    uint256 public diterimaGanda; // K3

    constructor(DocumentVerification dv_) {
        dv = dv_;
        aktor = [makeAddr("pengguna1"), makeAddr("pengguna2"), makeAddr("pengguna3")];
    }

    function hashKe(uint256 i) public pure returns (bytes32) {
        i %= JUMLAH_HASH;
        return i == D.JUMLAH ? bytes32(0) : D.hashDokumen(i);
    }

    function _cid(uint256 s) internal pure returns (string memory) {
        uint256 i = s % 6;
        return i == 5 ? "" : string.concat("cid-fiktif-", vm.toString(i));
    }

    function storeDocument(uint256 sAktor, uint256 sHash, uint256 sCid) external {
        address a = aktor[sAktor % 3];
        bytes32 h = hashKe(sHash);
        string memory cid = _cid(sCid);
        bool sudahAda = _catatan[h].diterima;
        vm.prank(a);
        try dv.storeDocument(h, cid) {
            if (h == bytes32(0)) ++diterimaHashKosong;
            if (bytes(cid).length == 0) ++diterimaCidKosong;
            if (sudahAda) ++diterimaGanda;
            else _catatan[h] = Catatan(true, cid, a, block.timestamp);
        } catch {}
    }

    /// @notice Memajukan waktu agar data waktu pendaftaran bervariasi (K4).
    function majukanWaktu(uint256 detik) external {
        vm.warp(block.timestamp + bound(detik, 1, 1 days));
    }

    function catatan(bytes32 h) external view returns (bool, string memory, address, uint256) {
        Catatan storage c = _catatan[h];
        return (c.diterima, c.cid, c.pendaftar, c.waktu);
    }
}
