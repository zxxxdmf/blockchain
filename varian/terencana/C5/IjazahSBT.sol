// SPDX-License-Identifier: MIT
// VARIAN: C5 - data ijazah yang sama dapat diterbitkan dua kali
pragma solidity 0.8.37;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Antarmuka ERC-5192 (Minimal Soulbound NFTs).
interface IERC5192 {
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    function locked(uint256 tokenId) external view returns (bool);
}

/// @title Kontrak acuan: ijazah fiktif sebagai Soulbound Token (ERC-721 + ERC-5192)
/// @notice Objek uji utama (subbab 2.1). Hanya menyimpan hash nomor ijazah, hash dokumen, alamat pemegang,
///         dan status token. Token yang dicabut tidak dibakar; penerbitan ulang membuat token pengganti.
/// @dev    Setiap pemeriksaan ditulis satu baris dalam bentuk `if (kondisi) revert ...;` atau
///         `if (kondisi) return Hasil...;` agar varian sistematis (Tahap 4) dapat dibangkitkan otomatis
///         dari semua pemeriksaan tanpa dipilih penulis. Jangan mengubah bentuk ini.
contract IjazahSBT is ERC721, AccessControl, IERC5192 {
    bytes32 public constant PENERBIT = keccak256("PENERBIT");

    /// @notice Empat hasil verifikasi (I7), diperiksa berurutan.
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
    /// @notice Hash nomor ijazah yang pernah diterbitkan (dua data ijazah sama bila hash nomornya sama).
    mapping(bytes32 => bool) public pernahTerdaftar;
    /// @notice Token aktif untuk setiap hash nomor (0 = tidak ada).
    mapping(bytes32 => uint256) public tokenAktif;
    /// @notice ID token diberikan berurutan mulai 1 agar ID berikutnya dapat dibaca sebelum PDF dibuat.
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

    // ------------------------------------------------------------------ peran (I6)

    /// @notice Menetapkan admin pertama; hanya dapat dipanggil satu kali, segera setelah deploy.
    function inisialisasi(address adminAwal) external {
        if (sudahDiinisialisasi) revert SudahDiinisialisasi();
        if (adminAwal == address(0)) revert AlamatNol();
        sudahDiinisialisasi = true;
        admin = adminAwal;
        _grantRole(DEFAULT_ADMIN_ROLE, adminAwal);
    }

    /// @notice Admin menyerahkan perannya kepada alamat lain.
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

    /// @dev Peran hanya berubah melalui fungsi di atas. Fungsi bawaan OpenZeppelin dinonaktifkan,
    ///      termasuk renounceRole (Tahap 2).
    function grantRole(bytes32, address) public pure override {
        revert FungsiDinonaktifkan();
    }

    function revokeRole(bytes32, address) public pure override {
        revert FungsiDinonaktifkan();
    }

    function renounceRole(bytes32, address) public pure override {
        revert FungsiDinonaktifkan();
    }

    // ------------------------------------------------------------------ penerbitan, pencabutan (I1, I3, I4, I5)

    function terbitkan(address pemegang, bytes32 hashNomor, bytes32 hashDokumen) external returns (uint256 id) {
        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();
        if (pemegang == address(0)) revert AlamatNol();
        if (hashNomor == bytes32(0) || hashDokumen == bytes32(0)) revert HashKosong();
        pernahTerdaftar[hashNomor] = true;
        id = _cetak(pemegang, hashNomor, hashDokumen);
    }

    /// @notice Status dicabut disimpan; token tidak dibakar agar riwayatnya tetap dapat diverifikasi.
    function cabut(uint256 id) external {
        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();
        if (_ownerOf(id) == address(0)) revert TokenTidakAda();
        if (_data[id].dicabut) revert SudahDicabut();
        _data[id].dicabut = true;
        delete tokenAktif[_data[id].hashNomor];
        emit IjazahDicabut(id);
    }

    /// @notice Menerbitkan token pengganti untuk data ijazah dari token yang telah dicabut (token lama).
    ///         Hash nomor tetap, hash dokumen baru.
    function terbitkanUlang(uint256 idLama, address pemegangBaru, bytes32 hashDokumenBaru)
        external
        returns (uint256 idBaru)
    {
        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();
        if (_ownerOf(idLama) == address(0)) revert TokenTidakAda();
        if (!_data[idLama].dicabut) revert BelumDicabut();
        if (tokenAktif[_data[idLama].hashNomor] != 0) revert MasihAdaTokenAktif();
        if (pemegangBaru == address(0)) revert AlamatNol();
        if (hashDokumenBaru == bytes32(0)) revert HashKosong();
        idBaru = _cetak(pemegangBaru, _data[idLama].hashNomor, hashDokumenBaru);
        emit IjazahDiterbitkanUlang(idLama, idBaru);
    }

    // ------------------------------------------------------------------ verifikasi (I7)

    /// @notice Dapat dipanggil siapa saja. Hasil diperiksa berurutan: tidak terdaftar, tidak cocok, dicabut, aktif.
    /// @param hashDiperiksa keccak256 dari nomor ijazah (setelah diseragamkan) atau dari seluruh isi berkas PDF.
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

    // ------------------------------------------------------------------ penguncian ERC-5192 (I2)

    /// @notice Selalu benar untuk token yang ada; gagal untuk token yang tidak ada.
    function locked(uint256 tokenId) external view returns (bool) {
        _requireOwned(tokenId);
        return true;
    }

    /// @dev Semua perpindahan token setelah diterbitkan ditolak (transferFrom, safeTransferFrom).
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (_ownerOf(tokenId) != address(0)) revert TokenTerkunci();
        return super._update(to, tokenId, auth);
    }

    function _cetak(address pemegang, bytes32 hashNomor, bytes32 hashDokumen) private returns (uint256 id) {
        id = idBerikutnya++;
        _data[id] = DataToken(hashNomor, hashDokumen, false);
        tokenAktif[hashNomor] = id;
        // forge-lint: disable-next-line(unsafe-oz-erc721-mint)
        _mint(pemegang, id); // pemegang adalah akun biasa; _safeMint tidak diperlukan
        emit Locked(id);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}
