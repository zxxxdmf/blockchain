"""Tahap 2: kontrak acuan di-deploy ke Anvil lokal dan dipanggil melalui cast untuk memastikan perilakunya sesuai
dengan aturan pada Tabel 2.1 (I1 sampai I7). Setiap panggilan yang harus ditolak dikirim dengan batas gas tetap agar
benar-benar masuk blok, sehingga statusnya (0 = ditolak) dapat dicatat.
Dijalankan oleh script/cek_aturan_anvil.sh (yang menyalakan Anvil dan men-deploy kontrak).
Pemakaian langsung: .venv/bin/python -I script/cek_aturan_anvil.py <rpc> <alamat kontrak>
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "jalur_qr"))
from bersama import Cast, keccak_teks  # noqa: E402

# akun bawaan Anvil (kunci uji publik, bukan akun penelitian)
KUNCI = {"admin": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
         "pemegang": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
         "penyerang": "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"}
ALAMAT = {"admin": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
          "pemegang": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
          "penyerang": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"}
HASIL = {"0": "TidakTerdaftar", "1": "TidakCocok", "2": "Dicabut", "3": "Aktif"}


def main(rpc, kontrak):
    c = Cast(rpc, kontrak)
    baris, ok_semua = [], True

    def kirim(aturan, oleh, sig, *arg, harus):
        nonlocal ok_semua
        r = c.send(sig, *arg, gas_limit=400_000, tanda=["--private-key", KUNCI[oleh]])
        hasil = "diterima" if r["status"] == 1 else "ditolak"
        ok = hasil == harus
        ok_semua &= ok
        baris.append((aturan, f"{oleh}.{sig.split('(')[0]}", harus, hasil, ok))

    def periksa(aturan, ket, sig, *arg, harus):
        nonlocal ok_semua
        nilai = c.call(sig, *arg).split()[0]
        nilai = HASIL.get(nilai, nilai) if sig.startswith("verifikasi") else nilai
        ok = nilai.lower() == harus.lower()
        ok_semua &= ok
        baris.append((aturan, ket, harus, nilai, ok))

    hn, hd, hd2 = keccak_teks("IJZ-FIKTIF-2026-201"), keccak_teks("dokumen 201"), keccak_teks("dokumen 201 #1")
    adm, pen = c.call("DEFAULT_ADMIN_ROLE()(bytes32)"), c.call("PENERBIT()(bytes32)")
    pemegang, penyerang, admin = ALAMAT["pemegang"], ALAMAT["penyerang"], ALAMAT["admin"]

    kirim("I1", "penyerang", "terbitkan(address,bytes32,bytes32)", penyerang, hn, hd, harus="ditolak")
    kirim("I1", "admin", "terbitkan(address,bytes32,bytes32)", pemegang, hn, hd, harus="diterima")  # admin juga penerbit
    periksa("I2", "ownerOf(1)", "ownerOf(uint256)(address)", "1", harus=pemegang)
    periksa("I2", "locked(1)", "locked(uint256)(bool)", "1", harus="true")
    kirim("I2", "pemegang", "transferFrom(address,address,uint256)", pemegang, penyerang, "1", harus="ditolak")
    kirim("I3", "penyerang", "cabut(uint256)", "1", harus="ditolak")
    kirim("I5", "admin", "terbitkan(address,bytes32,bytes32)", pemegang, hn, hd2, harus="ditolak")
    periksa("I7", "verifikasi(1, hash nomor) sebelum dicabut", "verifikasi(uint256,bytes32)(uint8)", "1", hn, harus="Aktif")
    kirim("I3", "admin", "cabut(uint256)", "1", harus="diterima")
    periksa("I7", "verifikasi(1, hash nomor) setelah dicabut", "verifikasi(uint256,bytes32)(uint8)", "1", hn, harus="Dicabut")
    kirim("I4", "admin", "cabut(uint256)", "1", harus="ditolak")
    kirim("I4", "penyerang", "terbitkanUlang(uint256,address,bytes32)", "1", penyerang, hd2, harus="ditolak")
    kirim("I4", "admin", "terbitkanUlang(uint256,address,bytes32)", "1", pemegang, hd2, harus="diterima")
    periksa("I4", "token lama tetap dicabut", "verifikasi(uint256,bytes32)(uint8)", "1", hn, harus="Dicabut")
    periksa("I7", "verifikasi(2, hash dokumen baru)", "verifikasi(uint256,bytes32)(uint8)", "2", hd2, harus="Aktif")
    periksa("I7", "verifikasi(2, hash dokumen lama)", "verifikasi(uint256,bytes32)(uint8)", "2", hd, harus="TidakCocok")
    periksa("I7", "verifikasi(99, hash nomor)", "verifikasi(uint256,bytes32)(uint8)", "99", hn, harus="TidakTerdaftar")
    kirim("I5", "admin", "terbitkanUlang(uint256,address,bytes32)", "1", pemegang, keccak_teks("dokumen 201 #2"), harus="ditolak")
    kirim("I6", "penyerang", "inisialisasi(address)", penyerang, harus="ditolak")
    kirim("I6", "penyerang", "gantiAdmin(address)", penyerang, harus="ditolak")
    kirim("I6", "penyerang", "tetapkanPenerbit(address)", penyerang, harus="ditolak")
    kirim("I6", "penyerang", "hapusPenerbit(address)", admin, harus="ditolak")
    kirim("I6", "admin", "grantRole(bytes32,address)", pen, penyerang, harus="ditolak")
    kirim("I6", "admin", "renounceRole(bytes32,address)", pen, admin, harus="ditolak")
    kirim("I6", "admin", "tetapkanPenerbit(address)", penyerang, harus="diterima")
    periksa("I6", "penyerang menjadi penerbit lewat admin", "hasRole(bytes32,address)(bool)", pen, penyerang, harus="true")
    kirim("I6", "admin", "hapusPenerbit(address)", penyerang, harus="diterima")
    periksa("I6", "peran penerbit penyerang dihapus", "hasRole(bytes32,address)(bool)", pen, penyerang, harus="false")
    kirim("I6", "admin", "gantiAdmin(address)", pemegang, harus="diterima")
    periksa("I6", "admin baru", "hasRole(bytes32,address)(bool)", adm, pemegang, harus="true")
    periksa("I6", "admin lama tidak lagi admin", "hasRole(bytes32,address)(bool)", adm, admin, harus="false")

    for aturan, ket, harus, hasil, ok in baris:
        print(f"  {aturan}  {ket:45s} harus {harus:14s} hasil {hasil:14s} {'SESUAI' if ok else 'TIDAK SESUAI'}")
    print(f"{sum(b[4] for b in baris)} dari {len(baris)} pemeriksaan sesuai")
    print("HASIL:", "LULUS" if ok_semua else "GAGAL")
    return 0 if ok_semua else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
