import argparse
import csv
import json

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from bersama import AKAR, DOKUMEN, KATEGORI, Cast, env_atau, keccak_berkas, keccak_teks, seragamkan


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rpc", default=env_atau("SEPOLIA_RPC_URL"))
    a = ap.parse_args()
    m = json.loads((DOKUMEN / "manifest.json").read_text())
    cast = Cast(a.rpc, m["kontrak"])
    baris = []
    for k in m["kasus"]:
        d = m["dokumen"][k["berkas"]]
        for masukan in k["masukan"]:
            h = keccak_teks(seragamkan(d["nomor"])) if masukan == "nomor" else keccak_berkas(DOKUMEN / k["berkas"])
            kode = int(cast.call("verifikasi(uint256,bytes32)(uint8)", str(d["id_token"]), h).split()[0])
            kategori = KATEGORI[kode]
            baris.append({"no": k["no"], "kasus": k["kasus"], "masukan": masukan, "id_token": d["id_token"],
                          "hash": h, "hasil_kontrak": kode, "kategori_cast": kategori, "diharapkan": k["diharapkan"],
                          "sesuai_cast": kategori == k["diharapkan"], "ditampilkan_halaman": "", "tangkapan_layar": ""})
            print(f"  kasus {k['no']} {masukan:5s}: {kategori:13s} diharapkan {k['diharapkan']:13s} "
                  f"{'SESUAI' if kategori == k['diharapkan'] else 'TIDAK SESUAI'}")
    p = AKAR / "hasil" / "olahan" / "qr_kasus.csv"
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(baris[0]))
        w.writeheader()
        w.writerows(baris)
    print(f"{sum(b['sesuai_cast'] for b in baris)} dari {len(baris)} pemeriksaan sesuai; tersimpan di {p.relative_to(AKAR)}")


if __name__ == "__main__":
    main()
