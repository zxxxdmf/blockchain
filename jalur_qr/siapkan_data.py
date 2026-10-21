import argparse
import csv
import json

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from bersama import AKAR, DOKUMEN, Cast, alamat_dari_teks, buat_pdf, env_atau, keccak_berkas, keccak_teks, seragamkan, tautan

IJAZAH = {"A": ("IJZ-FIKTIF-2026-101", "Mahasiswa Fiktif A"),
          "B": ("IJZ-FIKTIF-2026-102", "Mahasiswa Fiktif B"),
          "C": ("IJZ-FIKTIF-2026-103", "Mahasiswa Fiktif C")}
NOMOR_LAIN = "IJZ-FIKTIF-2026-104"
NOMOR_D6 = "IJZ-FIKTIF-2026-105"
ID_TIDAK_PERNAH_TERBIT = 9999


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rpc", default=env_atau("SEPOLIA_RPC_URL"))
    ap.add_argument("--kontrak", required=True)
    ap.add_argument("--kunci", default="")
    ap.add_argument("--akun", default=env_atau("AKUN_DEPLOY"))
    ap.add_argument("--sandi-file", default="")
    ap.add_argument("--url-halaman", required=True)
    ap.add_argument("--pemegang-a", required=True, help="alamat akun yang kuncinya dipegang penulis (uji penolakan transfer)")
    a = ap.parse_args()
    cast = Cast(a.rpc, a.kontrak, a.kunci, "" if a.kunci else a.akun, a.sandi_file)
    pemegang = {"A": a.pemegang_a, "B": alamat_dari_teks("pemegang fiktif B"), "C": alamat_dari_teks("pemegang fiktif C")}
    log = []
    dok = {}

    def catat(langkah, r):
        log.append({"langkah": langkah, **r})
        print(f"  {langkah:38s} status={r['status']} tx={r['tx']}")
        assert r["status"] == 1, f"{langkah} gagal di jaringan"

    def terbitkan(kode, nama_berkas, ulang_dari=None):
        nomor, nama = IJAZAH[kode]
        id_token = int(cast.call("idBerikutnya()(uint256)").split()[0])
        pdf = buat_pdf(nama_berkas, nomor, nama, tautan(a.url_halaman, id_token))
        h_nomor, h_pdf = keccak_teks(seragamkan(nomor)), keccak_berkas(pdf)
        if ulang_dari is None:
            catat(f"terbitkan {kode} (token {id_token})", cast.send("terbitkan(address,bytes32,bytes32)", pemegang[kode], h_nomor, h_pdf))
        else:
            catat(f"terbitkanUlang {kode} (token {ulang_dari} -> {id_token})",
                  cast.send("terbitkanUlang(uint256,address,bytes32)", str(ulang_dari), pemegang[kode], h_pdf))
        pemilik = cast.call("ownerOf(uint256)(address)", str(id_token))
        assert pemilik.lower() == pemegang[kode].lower(), "ID token yang terbit tidak sesuai dengan QR code"
        dok[nama_berkas] = {"id_token": id_token, "nomor": nomor, "nama": nama, "hash_nomor": h_nomor, "hash_pdf": h_pdf}
        return id_token

    id_a = terbitkan("A", "A_aktif.pdf")
    id_b = terbitkan("B", "B_dicabut.pdf")
    id_c = terbitkan("C", "C_lama.pdf")
    catat(f"cabut B (token {id_b})", cast.send("cabut(uint256)", str(id_b)))
    catat(f"cabut C (token {id_c})", cast.send("cabut(uint256)", str(id_c)))
    id_c2 = terbitkan("C", "C_pengganti.pdf", ulang_dari=id_c)

    def tambahan(nama_berkas, nomor, nama, id_qr):
        pdf = buat_pdf(nama_berkas, nomor, nama, tautan(a.url_halaman, id_qr))
        dok[nama_berkas] = {"id_token": id_qr, "nomor": nomor, "nama": nama,
                            "hash_nomor": keccak_teks(seragamkan(nomor)), "hash_pdf": keccak_berkas(pdf)}

    tambahan("D5_qr_ditempel.pdf", NOMOR_LAIN, "Pemegang Dokumen Lain", id_a)
    tambahan("D6_id_tidak_terbit.pdf", NOMOR_D6, "Mahasiswa Fiktif D", ID_TIDAK_PERNAH_TERBIT)
    tambahan("D7_nama_diubah.pdf", IJAZAH["A"][0], "Mahasiswa Fiktif Z", id_a)

    kasus = [
        (1, "ijazah aktif", "A_aktif.pdf", ["nomor", "pdf"], "asli"),
        (2, "ijazah yang dicabut tanpa penggantian", "B_dicabut.pdf", ["nomor", "pdf"], "tidak berlaku"),
        (3, "token lama setelah penerbitan ulang", "C_lama.pdf", ["nomor", "pdf"], "tidak berlaku"),
        (4, "token pengganti setelah penerbitan ulang", "C_pengganti.pdf", ["nomor", "pdf"], "asli"),
        (5, "QR code ijazah aktif yang ditempel pada dokumen lain", "D5_qr_ditempel.pdf", ["nomor", "pdf"], "palsu"),
        (6, "QR code berisi ID token yang tidak pernah diterbitkan", "D6_id_tidak_terbit.pdf", ["nomor", "pdf"], "palsu"),
        (7, "berkas PDF ijazah aktif yang nama fiktifnya diubah", "D7_nama_diubah.pdf", ["pdf"], "palsu"),
    ]
    manifest = {"kontrak": a.kontrak, "url_halaman": a.url_halaman, "pemegang": pemegang, "dokumen": dok,
                "kasus": [{"no": n, "kasus": k, "berkas": b, "masukan": m, "diharapkan": e} for n, k, b, m, e in kasus],
                "token": {"A": id_a, "B": id_b, "C_lama": id_c, "C_pengganti": id_c2}}
    (DOKUMEN / "manifest.json").write_text(json.dumps(manifest, indent=2))
    p_log = AKAR / "hasil" / "mentah" / "qr_transaksi.csv"
    p_log.parent.mkdir(parents=True, exist_ok=True)
    with open(p_log, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["langkah", "tx", "status", "blok"])
        w.writeheader()
        w.writerows(log)
    print(f"selesai: {len(dok)} PDF di {DOKUMEN.relative_to(AKAR)}, manifest.json, {p_log.relative_to(AKAR)}")


if __name__ == "__main__":
    main()
