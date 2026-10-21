import argparse
import csv
import json

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from bersama import AKAR, DOKUMEN, Cast, env_atau, keccak_teks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rpc", default=env_atau("SEPOLIA_RPC_URL"))
    ap.add_argument("--akun-pemegang", default="")
    ap.add_argument("--kunci-pemegang", default="")
    ap.add_argument("--sandi-file", default="")
    a = ap.parse_args()
    m = json.loads((DOKUMEN / "manifest.json").read_text())
    cast = Cast(a.rpc, m["kontrak"], a.kunci_pemegang, a.akun_pemegang, a.sandi_file)
    pemegang_a, id_a = m["pemegang"]["A"], m["token"]["A"]
    tujuan = m["pemegang"]["B"]
    hasil = []
    for langkah, sig, arg, gas in [
        ("transfer token A oleh pemiliknya", "transferFrom(address,address,uint256)", [pemegang_a, tujuan, str(id_a)], 200_000),
        ("penerbitan oleh alamat tanpa peran", "terbitkan(address,bytes32,bytes32)",
         [pemegang_a, keccak_teks("IJZ-FIKTIF-2026-199"), keccak_teks("dokumen tanpa peran")], 300_000),
    ]:
        r = cast.send(sig, *arg, gas_limit=gas)
        ok = r["status"] == 0
        hasil.append({"langkah": langkah, **r, "ditolak": ok})
        print(f"  {langkah:36s} status={r['status']} {'DITOLAK (sesuai)' if ok else 'DITERIMA (TIDAK SESUAI)'} tx={r['tx']}")
    pemilik = cast.call("ownerOf(uint256)(address)", str(id_a))
    print(f"  pemilik token A tetap: {pemilik.lower() == pemegang_a.lower()}")
    p = AKAR / "hasil" / "mentah" / "qr_penolakan.csv"
    with open(p, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(hasil[0]))
        w.writeheader()
        w.writerows(hasil)


if __name__ == "__main__":
    main()
