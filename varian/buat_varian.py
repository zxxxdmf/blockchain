"""Membangkitkan varian kontrak dengan cacat sisipan (Tahap 4) dari src/IjazahSBT.sol.

Kelompok terencana: C1 sampai C9 sesuai Tabel 2.6, masing-masing mengubah satu bagian kontrak acuan.
Kelompok sistematis: prinsip mutation testing. Dua aturan, yaitu menghapus pemeriksaan (H) dan membalik
kondisinya (B), diterapkan satu per satu pada SETIAP baris pemeriksaan `if (...) revert ...;` atau
`if (...) return Hasil...;` di kontrak acuan. Lokasi ditentukan oleh kode, tidak dipilih penulis; pustaka
OpenZeppelin tidak disentuh.

Keluaran:
  varian/terencana/<C>/IjazahSBT.sol, varian/terencana/daftar.csv
  varian/sistematis/<S..H|S..B>/IjazahSBT.sol, varian/sistematis/daftar.csv
Kolom `relevan` dan `golongan` di daftar.csv diisi dari usulan_golongan.csv (analisis kode) dan WAJIB ditinjau
serta di-commit sebelum eksekusi; golongan tidak diubah setelah eksekusi (Tahap 4).

Pemakaian: .venv/bin/python -I varian/buat_varian.py
"""
import csv
import pathlib
import re
import shutil

AKAR = pathlib.Path(__file__).resolve().parent.parent
ACUAN = AKAR / "src" / "IjazahSBT.sol"
DIR_T = AKAR / "varian" / "terencana"
DIR_S = AKAR / "varian" / "sistematis"
POLA = re.compile(r"^(?P<indent>\s*)if \((?P<kondisi>.+)\) (?P<aksi>revert \w+\(\)|return Hasil\.\w+);\s*$")

# ------------------------------------------------------------------ kelompok terencana (Tabel 2.6)
# (kode, invariant sasaran, golongan jumlah transaksi, cacat, rujukan, [(teks lama, teks baru)])
TERENCANA = [
    ("C1", "I1", "1", "fungsi penerbitan tanpa pemeriksaan peran", "Ussatova et al. (2026); Wei et al. (2025)",
     [("returns (uint256 id) {\n        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();\n",
       "returns (uint256 id) {\n")]),
    ("C2", "I2", ">1", "fungsi transfer tidak dikunci", "Daubenschütz dan Anders (2022)",
     [("        if (_ownerOf(tokenId) != address(0)) revert TokenTerkunci();\n", "")]),
    ("C3", "I3", ">1", "pencabutan dapat dilakukan selain penerbit", "Wankhede et al. (2023)",
     [("function cabut(uint256 id) external {\n        if (!hasRole(PENERBIT, msg.sender)) revert BukanPenerbit();\n",
       "function cabut(uint256 id) external {\n")]),
    ("C4", "I4", ">1", "token yang dicabut dapat diaktifkan kembali", "siklus hidup token (Gambar 2.1)",
     [("        if (_data[id].dicabut) revert SudahDicabut();\n        _data[id].dicabut = true;\n",
       "        _data[id].dicabut = !_data[id].dicabut; // pencabutan kedua mengaktifkan kembali token\n")]),
    ("C5", "I5", ">1", "data ijazah yang sama dapat diterbitkan dua kali", "Bimantoro et al. (2026)",
     [("        if (pernahTerdaftar[hashNomor]) revert DataGanda();\n", "")]),
    ("C6", "I6", "1", "penggantian admin tanpa pemeriksaan kewenangan", "Su et al. (2022)",
     [("function gantiAdmin(address baru) external {\n        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert BukanAdmin();\n",
       "function gantiAdmin(address baru) external {\n")]),
    ("C7", "I6", "1", "pengaman fungsi inisialisasi dihapus sehingga admin dapat ditetapkan ulang", "He et al. (2023)",
     [("        if (sudahDiinisialisasi) revert SudahDiinisialisasi();\n", "")]),
    ("C8", "I7", ">1", "fungsi verifikasi mengabaikan status dicabut", "Wankhede et al. (2023)",
     [("        if (d.dicabut) return Hasil.Dicabut;\n", "")]),
    ("C9", "I7", ">1", "fungsi verifikasi tidak mencocokkan hash sehingga token terdaftar selalu dinyatakan cocok",
     "Bimantoro et al. (2026)",
     [("        if (hashDiperiksa != d.hashNomor && hashDiperiksa != d.hashDokumen) return Hasil.TidakCocok;\n", "")]),
]


def tandai(sumber: str, catatan: str) -> str:
    baris = sumber.split("\n", 1)
    return f"{baris[0]}\n// VARIAN: {catatan}\n{baris[1]}"


def tulis(dir_varian: pathlib.Path, isi: str) -> None:
    dir_varian.mkdir(parents=True, exist_ok=True)
    (dir_varian / "IjazahSBT.sol").write_text(isi)


def terencana(acuan: str) -> None:
    rows = []
    for kode, sasaran, gol, cacat, rujukan, ganti in TERENCANA:
        isi = acuan
        for lama, baru in ganti:
            assert isi.count(lama) == 1, f"{kode}: teks yang diganti harus muncul tepat satu kali"
            isi = isi.replace(lama, baru)
        tulis(DIR_T / kode, tandai(isi, f"{kode} - {cacat}"))
        rows.append({"kode": kode, "invariant_sasaran": sasaran, "golongan": gol, "cacat": cacat, "rujukan": rujukan})
    with open(DIR_T / "daftar.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"terencana: {len(rows)} varian")


def sistematis(acuan: str) -> None:
    usulan = {}
    p_usulan = DIR_S / "usulan_golongan.csv"
    if p_usulan.exists():
        with open(p_usulan) as f:
            for r in csv.DictReader(f):
                usulan[r["id"]] = r
    baris = acuan.split("\n")
    fungsi = "-"
    rows = []
    no = 0
    for i, teks in enumerate(baris):
        m_f = re.search(r"\bfunction (\w+)\(", teks)
        if m_f:
            fungsi = m_f.group(1)
        m = POLA.match(teks)
        if not m:
            continue
        no += 1
        for op in ("H", "B"):
            vid = f"S{no:02d}{op}"
            salin = list(baris)
            if op == "H":
                salin[i] = f"{m['indent']}// [{vid}] pemeriksaan dihapus: {teks.strip()}"
                ket = "hapus pemeriksaan"
            else:
                salin[i] = f"{m['indent']}if (!({m['kondisi']})) {m['aksi']}; // [{vid}] kondisi dibalik"
                ket = "balik kondisi"
            tulis(DIR_S / vid, tandai("\n".join(salin), f"{vid} - {ket} pada {fungsi}() baris {i + 1}"))
            u = usulan.get(vid, {})
            rows.append({
                "id": vid, "fungsi": fungsi, "baris": i + 1, "operator": ket, "pemeriksaan_asli": teks.strip(),
                "relevan": u.get("relevan", ""), "golongan": u.get("golongan", ""), "alasan": u.get("alasan", ""),
            })
    with open(DIR_S / "daftar.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    kosong = sum(1 for r in rows if not r["golongan"])
    print(f"sistematis: {no} pemeriksaan x 2 aturan = {len(rows)} varian; tanpa golongan: {kosong}")


if __name__ == "__main__":
    acuan = ACUAN.read_text()
    for d in (DIR_T, DIR_S):
        for sub in d.iterdir() if d.exists() else []:
            if sub.is_dir():
                shutil.rmtree(sub)
    terencana(acuan)
    sistematis(acuan)
