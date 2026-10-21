// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC5192 {
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    function locked(uint256 tokenId) external view returns (bool);
}

contract IjazahSBT is ERC721, AccessControl, IERC5192 {
    bytes32 public constant PENERBIT = keccak256("PENERBIT");

    enum Hasil {
        TidakTerdaftar,
        TidakCocok,
        Dicabut,
        Aktif
    }

    struct DataToken {
        bytes32 hashNomor;
        bytes32 hashDokumen;
        bool dicabut;
    }

    mapping(uint256 => DataToken) private _data;
    mapping(bytes32 => bool) public pernahTerdaftar;
    mapping(bytes32 => uint256) public tokenAktif;
    uint256 public idBerikutnya = 1;
    bool public sudahDiinisialisasi;
    address public admin;

    error SudahDiinisialisasi();
    error AlamatNol();
    error HashKosong();
    error BukanAdmin();
    error BukanPenerbit();
    error DataGanda();
    error TokenTidakAda();
    error SudahDicabut();
    error BelumDicabut();
    error MasihAdaTokenAktif();
    error TokenTerkunci();
    error FungsiDinonaktifkan();

    event IjazahDicabut(uint256 indexed id);
    event IjazahDiterbitkanUlang(uint256 indexed idLama, uint256 indexed idBaru);
    event AdminDiganti(address indexed lama, address indexed baru);

    constructor() ERC721("Ijazah Fiktif SBT", "IJZF") {}

    function inisialisasi(address adminAwal) external {
        if (sudahDiinisialisasi) revert SudahDiinisialisasi();
        if (adminAwal == address(0)) revert AlamatNol();
        sudahDiinisialisasi = true;
        admin = adminAwal;
        _grantRole(DEFAULT_ADMIN_ROLE, adminAwal);
    }

    function gantiAdmin(address baru) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert BukanAdmin();
        if (baru == address(0)) revert AlamatNol();
        address lama = admin;
        _revokeRole(DEFAULT_ADMIN_ROLE, lama);
        admin = baru;
        _grantRole(DEFAULT_ADMIN_ROLE, baru);
        emit AdminDiganti(lama, baru);
    }

    function tetapkanPenerbit(address akun) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert BukanAdmin();
        if (akun == address(0)) revert AlamatNol();
        _grantRole(PENERBIT, akun);
    }

    function hapusPenerbit(address akun) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert BukanAdmin();
        _revokeRole(PENERBIT, akun);
    }

    function grantRole(bytes32, address) public pure override {
        revert FungsiDinonaktifkan();
    }

    function revokeRole(bytes32, address) public pure override {
        revert FungsiDinonaktifkan();
    }

    function renounceRole(bytes32, address) public pure override {
        revert FungsiDinonaktifkan();
    }

    function terbitkan(address pemegang, bytes32 hashNomor, bytes32 hashDokumen) external returns (uint256 id) {
        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();
        if (pemegang == address(0)) revert AlamatNol();
        if (hashNomor == bytes32(0) || hashDokumen == bytes32(0)) revert HashKosong();
        if (pernahTerdaftar[hashNomor]) revert DataGanda();
        pernahTerdaftar[hashNomor] = true;
        id = _cetak(pemegang, hashNomor, hashDokumen);
    }

    function cabut(uint256 id) external {
        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();
        if (_ownerOf(id) == address(0)) revert TokenTidakAda();
        if (_data[id].dicabut) revert SudahDicabut();
        _data[id].dicabut = true;
        delete tokenAktif[_data[id].hashNomor];
        emit IjazahDicabut(id);
    }

    function terbitkanUlang(uint256 idLama, address pemegangBaru, bytes32 hashDokumenBaru)
        external
        returns (uint256 idBaru)
    {
        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();
        if (_ownerOf(idLama) == address(0)) revert TokenTidakAda();
        if (!_data[idLama].dicabut) revert BelumDicabut();
        if (tokenAktif[_data[idLama].hashNomor] != 0) revert MasihAdaTokenAktif();
        if (hashDokumenBaru == bytes32(0)) revert HashKosong();
        idBaru = _cetak(pemegangBaru, _data[idLama].hashNomor, hashDokumenBaru);
        emit IjazahDiterbitkanUlang(idLama, idBaru);
    }

    function verifikasi(uint256 id, bytes32 hashDiperiksa) external view returns (Hasil) {
        if (_ownerOf(id) == address(0)) return Hasil.TidakTerdaftar;
        DataToken storage d = _data[id];
        if (hashDiperiksa != d.hashNomor && hashDiperiksa != d.hashDokumen) return Hasil.TidakCocok;
        if (d.dicabut) return Hasil.Dicabut;
        return Hasil.Aktif;
    }

    function dataToken(uint256 id) external view returns (bytes32 hashNomor, bytes32 hashDokumen, bool dicabut) {
        DataToken storage d = _data[id];
        return (d.hashNomor, d.hashDokumen, d.dicabut);
    }

    function locked(uint256 tokenId) external view returns (bool) {
        _requireOwned(tokenId);
        return true;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (_ownerOf(tokenId) != address(0)) revert TokenTerkunci();
        return super._update(to, tokenId, auth);
    }

    function _cetak(address pemegang, bytes32 hashNomor, bytes32 hashDokumen) private returns (uint256 id) {
        id = idBerikutnya++;
        _data[id] = DataToken(hashNomor, hashDokumen, false);
        tokenAktif[hashNomor] = id;
        _mint(pemegang, id);
        emit Locked(id);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}
