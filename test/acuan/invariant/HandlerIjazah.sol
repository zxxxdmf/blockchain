// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {IjazahSBT} from "src/IjazahSBT.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";

/// @title Handler kontrak acuan (Tahap 3)
/// @notice Membungkus kontrak acuan: nilai acak forge dipetakan menjadi aktor (admin, penerbit, dua pemegang,
///         penyerang) dan menjadi salah satu dari sepuluh data ijazah sintetis. Variabel bayangan hanya diperbarui
///         bila panggilan berhasil DAN dilakukan oleh pihak yang berwenang menurut catatan handler sendiri.
///         Jawaban seharusnya untuk I7 diturunkan dari fakta pada variabel bayangan (token yang terbit, token yang
///         dicabut, hash yang tercatat), tidak disusun dengan menyalin kode fungsi verifikasi.
contract HandlerIjazah is Test {
    IjazahSBT public immutable ijazah;
    address[5] public aktor; // 0 admin awal, 1 penerbit awal, 2 pemegang A, 3 pemegang B, 4 penyerang

    // ---------------- variabel bayangan: peran (I1, I6)
    address public bayanganAdmin;
    mapping(address => bool) public bayanganPenerbit;
    uint256 public inisialisasiUlangBerhasil;

    // ---------------- variabel bayangan: token
    uint256 public jumlahTerbitSah; // penerbitan berhasil oleh penerbit menurut catatan handler (I1)
    mapping(uint256 => address) public pemilikAwal; // setiap penerbitan yang berhasil (I2)
    mapping(uint256 => bool) public terbitSah; // token diterbitkan oleh penerbit tercatat
    mapping(uint256 => bool) public pengganti; // token pengganti hasil terbitkanUlang oleh penerbit tercatat (I4)
    mapping(uint256 => bytes32) public catatanHashNomor;
    mapping(uint256 => bytes32) public catatanHashDokumen;
    mapping(uint256 => bool) public dicabutSah; // dicabut oleh penerbit tercatat (I3, I7)
    mapping(uint256 => bool) public pernahDicabut; // pernah berstatus dicabut setelah pencabutan berhasil (I4)
    mapping(bytes32 => bool) public dataPernahDicabut; // hash nomor yang salah satu tokennya pernah dicabut (I4)
    mapping(bytes32 => uint256) private _indeksData; // hash nomor -> indeks data sintetis + 1
    uint256 public urutTerbitUlang;

    // ---------------- I7: jumlah jawaban kontrak yang berbeda dari jawaban seharusnya, per jawaban seharusnya
    uint256[4] public salahVerifikasi;
    uint256 public jumlahPanggilan;

    constructor(IjazahSBT ijazah_, address[5] memory aktor_) {
        ijazah = ijazah_;
        aktor = aktor_;
        bayanganAdmin = aktor_[0];
        bayanganPenerbit[aktor_[1]] = true;
        for (uint256 k; k < D.JUMLAH; ++k) {
            _indeksData[D.hashNomor(k)] = k + 1;
        }
    }

    // ------------------------------------------------------------------ pemetaan nilai acak

    function _aktor(uint256 s) internal view returns (address) {
        return aktor[s % 5];
    }

    /// @dev ID dari 0 sampai idBerikutnya (termasuk ID yang belum pernah diterbitkan).
    function _id(uint256 s) internal view returns (uint256) {
        return s % (ijazah.idBerikutnya() + 1);
    }

    // ------------------------------------------------------------------ penerbitan

    function terbitkan(uint256 sAktor, uint256 sPemegang, uint256 sData) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        address p = aktor[2 + sPemegang % 2];
        uint256 k = sData % D.JUMLAH;
        vm.prank(a);
        try ijazah.terbitkan(p, D.hashNomor(k), D.hashDokumen(k)) returns (uint256 id) {
            pemilikAwal[id] = p;
            if (bayanganPenerbit[a]) {
                ++jumlahTerbitSah;
                terbitSah[id] = true;
                catatanHashNomor[id] = D.hashNomor(k);
                catatanHashDokumen[id] = D.hashDokumen(k);
            }
        } catch {}
    }

    function terbitkanUlang(uint256 sAktor, uint256 sId, uint256 sPemegang) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        address p = aktor[2 + sPemegang % 2];
        uint256 idLama = _id(sId);
        bytes32 hn = catatanHashNomor[idLama];
        if (hn == bytes32(0)) (hn,,) = ijazah.dataToken(idLama);
        uint256 k = _indeksData[hn] == 0 ? 0 : _indeksData[hn] - 1;
        bytes32 hdBaru = D.hashDokumenPengganti(k, urutTerbitUlang + 1);
        vm.prank(a);
        try ijazah.terbitkanUlang(idLama, p, hdBaru) returns (uint256 idBaru) {
            ++urutTerbitUlang;
            pemilikAwal[idBaru] = p;
            if (bayanganPenerbit[a]) {
                ++jumlahTerbitSah;
                terbitSah[idBaru] = true;
                pengganti[idBaru] = true;
                catatanHashNomor[idBaru] = hn;
                catatanHashDokumen[idBaru] = hdBaru;
            }
        } catch {}
    }

    function cabut(uint256 sAktor, uint256 sId) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        uint256 id = _id(sId);
        // dibaca SEBELUM vm.prank: panggilan eksternal di antara prank dan cabut akan memakai prank tersebut
        bool tokenAda = id != 0 && id < ijazah.idBerikutnya();
        vm.prank(a);
        try ijazah.cabut(id) {
            (bytes32 hn,, bool dicabut) = ijazah.dataToken(id);
            // hanya token yang sudah diterbitkan; pencabutan ID yang belum ada tidak dicatat sebagai riwayat token
            if (dicabut && tokenAda) {
                pernahDicabut[id] = true;
                dataPernahDicabut[hn] = true;
            }
            if (bayanganPenerbit[a] && tokenAda) dicabutSah[id] = true;
        } catch {}
    }

    /// @notice Percobaan memindahkan token; aktor dapat berupa pemiliknya sendiri maupun pihak lain.
    function transfer(uint256 sAktor, uint256 sId, uint256 sKe, bool aman) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        uint256 id = _id(sId);
        address ke = _aktor(sKe);
        address dari = pemilikAwal[id] == address(0) ? a : pemilikAwal[id];
        vm.prank(a);
        if (aman) {
            try ijazah.safeTransferFrom(dari, ke, id) {} catch {}
        } else {
            try ijazah.transferFrom(dari, ke, id) {} catch {}
        }
    }

    // ------------------------------------------------------------------ peran

    function gantiAdmin(uint256 sAktor, uint256 sBaru) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        address b = _aktor(sBaru);
        vm.prank(a);
        try ijazah.gantiAdmin(b) {
            if (a == bayanganAdmin) bayanganAdmin = b;
        } catch {}
    }

    function tetapkanPenerbit(uint256 sAktor, uint256 sAkun) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        address b = _aktor(sAkun);
        vm.prank(a);
        try ijazah.tetapkanPenerbit(b) {
            if (a == bayanganAdmin) bayanganPenerbit[b] = true;
        } catch {}
    }

    function hapusPenerbit(uint256 sAktor, uint256 sAkun) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        address b = _aktor(sAkun);
        vm.prank(a);
        try ijazah.hapusPenerbit(b) {
            if (a == bayanganAdmin) bayanganPenerbit[b] = false;
        } catch {}
    }

    /// @notice Memanggil ulang fungsi inisialisasi dengan aktor acak; harus selalu ditolak.
    function inisialisasiUlang(uint256 sAktor, uint256 sAdmin) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        vm.prank(a);
        try ijazah.inisialisasi(_aktor(sAdmin)) {
            ++inisialisasiUlangBerhasil;
        } catch {}
    }

    // ------------------------------------------------------------------ verifikasi (I7)

    /// @notice Memanggil fungsi verifikasi dengan ID acak (termasuk ID yang belum diterbitkan) dan hash yang
    ///         diambil dari data tercatat maupun hash lain, lalu membandingkannya dengan jawaban seharusnya.
    function verifikasi(uint256 sId, uint256 sHash) external {
        ++jumlahPanggilan;
        uint256 id = _id(sId);
        bytes32 h;
        uint256 pilih = sHash % 4;
        if (pilih == 0) h = catatanHashNomor[id];
        else if (pilih == 1) h = catatanHashDokumen[id];
        else if (pilih == 2) h = D.hashNomor(sHash / 4);
        else h = keccak256(abi.encode(sHash));

        uint8 seharusnya = _jawabanSeharusnya(id, h);
        uint8 jawaban = uint8(ijazah.verifikasi(id, h));
        if (jawaban != seharusnya) ++salahVerifikasi[seharusnya];
    }

    /// @dev Disusun dari fakta bayangan sesuai uraian I7 (Tabel 2.1 dan paragraf sesudahnya).
    function _jawabanSeharusnya(uint256 id, bytes32 h) internal view returns (uint8) {
        bool terbit = terbitSah[id];
        bool hashTercatat = h != bytes32(0) && (h == catatanHashNomor[id] || h == catatanHashDokumen[id]);
        if (!terbit) return uint8(IjazahSBT.Hasil.TidakTerdaftar);
        if (!hashTercatat) return uint8(IjazahSBT.Hasil.TidakCocok);
        if (dicabutSah[id]) return uint8(IjazahSBT.Hasil.Dicabut);
        return uint8(IjazahSBT.Hasil.Aktif);
    }

    // ------------------------------------------------------------------ pembantu invariant
    function aktorKe(uint256 i) external view returns (address) {
        return aktor[i];
    }
}
