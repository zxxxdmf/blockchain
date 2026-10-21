// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {IjazahSBT} from "src/IjazahSBT.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";

contract HandlerIjazah is Test {
    IjazahSBT public immutable ijazah;
    address[5] public aktor;

    address public bayanganAdmin;
    mapping(address => bool) public bayanganPenerbit;
    uint256 public inisialisasiUlangBerhasil;

    uint256 public jumlahTerbitSah;
    mapping(uint256 => address) public pemilikAwal;
    mapping(uint256 => bool) public terbitSah;
    mapping(uint256 => bool) public pengganti;
    mapping(uint256 => bytes32) public catatanHashNomor;
    mapping(uint256 => bytes32) public catatanHashDokumen;
    mapping(uint256 => bool) public dicabutSah;
    mapping(uint256 => bool) public pernahDicabut;
    mapping(bytes32 => bool) public dataPernahDicabut;
    mapping(bytes32 => uint256) private _indeksData;
    uint256 public urutTerbitUlang;

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

    function _aktor(uint256 s) internal view returns (address) {
        return aktor[s % 5];
    }

    function _id(uint256 s) internal view returns (uint256) {
        return s % (ijazah.idBerikutnya() + 1);
    }

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
        bool tokenAda = id != 0 && id < ijazah.idBerikutnya();
        vm.prank(a);
        try ijazah.cabut(id) {
            (bytes32 hn,, bool dicabut) = ijazah.dataToken(id);
            if (dicabut && tokenAda) {
                pernahDicabut[id] = true;
                dataPernahDicabut[hn] = true;
            }
            if (bayanganPenerbit[a] && tokenAda) dicabutSah[id] = true;
        } catch {}
    }

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

    function inisialisasiUlang(uint256 sAktor, uint256 sAdmin) external {
        ++jumlahPanggilan;
        address a = _aktor(sAktor);
        vm.prank(a);
        try ijazah.inisialisasi(_aktor(sAdmin)) {
            ++inisialisasiUlangBerhasil;
        } catch {}
    }

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

    function _jawabanSeharusnya(uint256 id, bytes32 h) internal view returns (uint8) {
        bool terbit = terbitSah[id];
        bool hashTercatat = h != bytes32(0) && (h == catatanHashNomor[id] || h == catatanHashDokumen[id]);
        if (!terbit) return uint8(IjazahSBT.Hasil.TidakTerdaftar);
        if (!hashTercatat) return uint8(IjazahSBT.Hasil.TidakCocok);
        if (dicabutSah[id]) return uint8(IjazahSBT.Hasil.Dicabut);
        return uint8(IjazahSBT.Hasil.Aktif);
    }

    function aktorKe(uint256 i) external view returns (address) {
        return aktor[i];
    }
}
