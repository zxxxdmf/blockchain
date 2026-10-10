"""Menjalankan setiap kampanye stateful fuzzing dan unit test secara berurutan, lalu mencatat hasilnya (Tahap 5).

Satu kampanye = satu invariant x satu kontrak (acuan, varian, atau pembanding) x satu seed. Untuk setiap kampanye:
  1. cache/invariant dihapus (Foundry memutar ulang kegagalan lama bila tidak dihapus);
  2. eksekusi pertama TANPA shrinking (FOUNDRY_INVARIANT_SHRINK_RUN_LIMIT=0): status, runs, calls, durasi;
  3. bila terdeteksi, eksekusi kedua DENGAN shrinking bawaan untuk urutan terpendek (dianalisis di Tahap 6).
Varian dijalankan di folder kerja terpisah (otomasi/_kerja/<target>) sehingga src/ asli tidak pernah diubah.

Pemakaian (dari folder eksperimen):
  .venv/bin/python -I otomasi/jalankan.py acuan                 # I1..I7 x seed 1..10 (kontrol)
  .venv/bin/python -I otomasi/jalankan.py terencana             # C1..C9 pada invariant sasarannya
  .venv/bin/python -I otomasi/jalankan.py sistematis            # S..H/S..B pada ketujuh invariant
  .venv/bin/python -I otomasi/jalankan.py pembanding            # K1..K5 x seed 1..10
  .venv/bin/python -I otomasi/jalankan.py unit                  # unit test sekali pada setiap varian
Opsi: --seed 1-3 | --target C1,C8 | --invariant I7 | --ulang (abaikan hasil yang sudah tercatat)
"""
import argparse
import csv
import datetime
import json
import os
import pathlib
import re
import shutil
import subprocess

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = AKAR / "otomasi" / "_kerja"
MENTAH = AKAR / "hasil" / "mentah"
OLAHAN = AKAR / "hasil" / "olahan"
INV_ACUAN = [f"I{i}" for i in range(1, 8)]
INV_PEMBANDING = [f"K{i}" for i in range(1, 6)]
JALUR_INV_ACUAN = "test/acuan/invariant/IjazahSBT.invariant.t.sol"
JALUR_INV_PEMBANDING = "test/pembanding/DocumentVerification.invariant.t.sol"
KOLOM_KAMPANYE = ["kelompok", "target", "invariant", "seed", "status", "runs", "calls", "reverts", "durasi_ms",
                  "alasan", "panjang_urutan_awal", "panjang_urutan_shrink", "berkas_mentah", "waktu"]
KOLOM_UNIT = ["target", "status", "jumlah_gagal", "tes_gagal", "berkas_mentah", "waktu"]


# ------------------------------------------------------------------ persiapan folder kerja

def siapkan_kerja(target: str, sumber: pathlib.Path) -> tuple[pathlib.Path, str]:
    """Salin konfigurasi, test, dan kontrak target ke folder kerja; lib ditautkan. Kembalikan (folder, status)."""
    d = KERJA / target
    if d.exists():
        shutil.rmtree(d)
    (d / "src").mkdir(parents=True)
    shutil.copy(AKAR / "foundry.toml", d / "foundry.toml")
    shutil.copytree(AKAR / "test", d / "test")
    shutil.copytree(AKAR / "src" / "pembanding", d / "src" / "pembanding")
    shutil.copy(sumber, d / "src" / "IjazahSBT.sol")
    os.symlink(AKAR / "lib", d / "lib")
    p = subprocess.run(["forge", "build"], cwd=d, capture_output=True, text=True)
    return d, ("ok" if p.returncode == 0 else "galat_kompilasi")


# ------------------------------------------------------------------ eksekusi dan pembacaan keluaran forge

def ke_ms(teks: str) -> float:
    satuan = {"s": 1000.0, "ms": 1.0, "µs": 1e-3, "us": 1e-3, "ns": 1e-6}
    return round(sum(float(n) * satuan[u] for n, u in re.findall(r"([\d.]+)\s*(ms|µs|us|ns|s)\b", teks)), 3)


def forge_test(cwd: pathlib.Path, jalur: str, uji: str | None, seed: int | None, shrink: bool) -> dict:
    shutil.rmtree(cwd / "cache" / "invariant", ignore_errors=True)
    env = dict(os.environ)
    if not shrink:
        env["FOUNDRY_INVARIANT_SHRINK_RUN_LIMIT"] = "0"
    cmd = ["forge", "test", "--match-path", jalur, "--json"]
    if uji:
        cmd += ["--match-test", f"^{uji}\\(\\)$"]
    if seed is not None:
        cmd += ["--fuzz-seed", str(seed)]
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=env)
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError:
        return {"_galat": (p.stdout + p.stderr)[-2000:]}


def baca_kampanye(hasil: dict) -> dict:
    if "_galat" in hasil:
        return {"status": "galat", "alasan": hasil["_galat"][-300:]}
    suite = next(iter(hasil.values()))
    if not suite["test_results"]:
        return {"status": "galat", "alasan": "tidak ada tes yang cocok"}
    nama, r = next(iter(suite["test_results"].items()))
    inv = (r.get("kind") or {}).get("Invariant", {})
    keluar = {"runs": inv.get("runs", ""), "calls": inv.get("calls", ""), "reverts": inv.get("reverts", ""),
              "durasi_ms": ke_ms(r.get("duration", "")), "alasan": "", "panjang": ""}
    if r["status"] == "Success":
        keluar["status"] = "lulus"
    elif r.get("invariant_failures"):
        f = r["invariant_failures"][0]
        keluar["status"] = "terdeteksi"
        keluar["alasan"] = f.get("reason", "")
        seq = (f.get("counterexample") or {}).get("Sequence")
        if seq:
            keluar["panjang"] = len(seq[1]) if isinstance(seq, list) and len(seq) == 2 else len(seq)
    else:
        alasan = str(r.get("reason") or "")
        keluar["status"] = "gagal_disiapkan" if "setUp" in alasan or nama.startswith("setUp") else "galat"
        keluar["alasan"] = alasan[:300]
    return keluar


# ------------------------------------------------------------------ pencatatan

def baca_csv(p: pathlib.Path) -> list[dict]:
    return list(csv.DictReader(open(p))) if p.exists() else []


def tambah_csv(p: pathlib.Path, kolom: list[str], baris: dict) -> None:
    baru = not p.exists()
    with open(p, "a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=kolom)
        if baru:
            w.writeheader()
        w.writerow(baris)


def simpan_mentah(nama: str, data: dict) -> str:
    p = MENTAH / f"{nama}.json"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=1, default=str))
    return str(p.relative_to(AKAR))


def kampanye(kelompok, target, cwd, jalur, inv, seed, sudah, csv_out):
    kunci = (kelompok, target, inv, str(seed))
    if kunci in sudah:
        return
    uji = f"invariant_{inv}"
    h1 = forge_test(cwd, jalur, uji, seed, shrink=False)
    r1 = baca_kampanye(h1)
    berkas = simpan_mentah(f"{kelompok}/{target}_{inv}_s{seed}", h1)
    shrink = ""
    if r1["status"] == "terdeteksi":
        h2 = forge_test(cwd, jalur, uji, seed, shrink=True)
        r2 = baca_kampanye(h2)
        simpan_mentah(f"{kelompok}/{target}_{inv}_s{seed}_shrink", h2)
        shrink = r2.get("panjang", "")
    baris = {"kelompok": kelompok, "target": target, "invariant": inv, "seed": seed, "status": r1["status"],
             "runs": r1.get("runs", ""), "calls": r1.get("calls", ""), "reverts": r1.get("reverts", ""),
             "durasi_ms": r1.get("durasi_ms", ""), "alasan": r1.get("alasan", ""),
             "panjang_urutan_awal": r1.get("panjang", ""), "panjang_urutan_shrink": shrink, "berkas_mentah": berkas,
             "waktu": datetime.datetime.now().isoformat(timespec="seconds")}
    tambah_csv(csv_out, KOLOM_KAMPANYE, baris)
    print(f"  {target:6s} {inv} seed {seed:2d}: {r1['status']:11s} calls={r1.get('calls', '')} "
          f"durasi={r1.get('durasi_ms', '')} ms shrink={shrink}")


# ------------------------------------------------------------------ daftar target

def daftar_varian(kelompok: str) -> list[dict]:
    p = AKAR / "varian" / kelompok / "daftar.csv"
    baris = baca_csv(p)
    kunci = "kode" if kelompok == "terencana" else "id"
    return [{"target": b[kunci], "sasaran": b.get("invariant_sasaran"), "golongan": b.get("golongan", "")} for b in baris]


def rentang(teks: str) -> list[int]:
    a, _, b = teks.partition("-")
    return list(range(int(a), int(b or a) + 1))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("kelompok", choices=["acuan", "terencana", "sistematis", "pembanding", "unit"])
    ap.add_argument("--seed", default="1-10")
    ap.add_argument("--target", default="")
    ap.add_argument("--invariant", default="")
    ap.add_argument("--ulang", action="store_true")
    a = ap.parse_args()
    OLAHAN.mkdir(parents=True, exist_ok=True)
    seeds = rentang(a.seed)
    pilih_target = set(filter(None, a.target.split(",")))
    pilih_inv = set(filter(None, a.invariant.split(",")))
    csv_out = OLAHAN / ("unit.csv" if a.kelompok == "unit" else "kampanye.csv")
    sudah = set() if a.ulang else {
        (b["kelompok"], b["target"], b["invariant"], b["seed"]) for b in baca_csv(OLAHAN / "kampanye.csv")}

    if a.kelompok == "acuan":
        cwd, st = siapkan_kerja("acuan", AKAR / "src" / "IjazahSBT.sol")
        assert st == "ok", "kontrak acuan gagal dikompilasi"
        for inv in INV_ACUAN:
            if pilih_inv and inv not in pilih_inv:
                continue
            for s in seeds:
                kampanye("acuan", "acuan", cwd, JALUR_INV_ACUAN, inv, s, sudah, csv_out)
        return

    if a.kelompok == "pembanding":
        for inv in INV_PEMBANDING:
            if pilih_inv and inv not in pilih_inv:
                continue
            for s in seeds:
                kampanye("pembanding", "pembanding", AKAR, JALUR_INV_PEMBANDING, inv, s, sudah, csv_out)
        return

    if a.kelompok == "unit":
        sudah_unit = set() if a.ulang else {b["target"] for b in baca_csv(csv_out)}
        sasaran = [("acuan", AKAR / "src" / "IjazahSBT.sol")]
        for kel in ("terencana", "sistematis"):
            sasaran += [(v["target"], AKAR / "varian" / kel / v["target"] / "IjazahSBT.sol") for v in daftar_varian(kel)]
        for target, sumber in sasaran:
            if (pilih_target and target not in pilih_target) or target in sudah_unit:
                continue
            cwd, st = siapkan_kerja(target, sumber)
            gagal, berkas = [], ""
            if st == "ok":
                h = forge_test(cwd, "test/acuan/unit/*", None, None, shrink=True)
                berkas = simpan_mentah(f"unit/{target}", h)
                if "_galat" in h:
                    st = "galat"
                else:
                    for suite in h.values():
                        gagal += [n for n, r in suite["test_results"].items() if r["status"] != "Success"]
                    st = "terdeteksi" if gagal else "lolos"
            tambah_csv(csv_out, KOLOM_UNIT, {"target": target, "status": st, "jumlah_gagal": len(gagal),
                                             "tes_gagal": ";".join(gagal), "berkas_mentah": berkas,
                                             "waktu": datetime.datetime.now().isoformat(timespec="seconds")})
            print(f"  {target:6s}: {st} ({len(gagal)} kasus gagal)")
        return

    # terencana: hanya invariant sasaran; sistematis: ketujuh invariant
    for v in daftar_varian(a.kelompok):
        if pilih_target and v["target"] not in pilih_target:
            continue
        cwd, st = siapkan_kerja(v["target"], AKAR / "varian" / a.kelompok / v["target"] / "IjazahSBT.sol")
        invs = [v["sasaran"]] if a.kelompok == "terencana" else INV_ACUAN
        for inv in invs:
            if pilih_inv and inv not in pilih_inv:
                continue
            for s in seeds:
                if st != "ok":
                    tambah_csv(csv_out, KOLOM_KAMPANYE, {"kelompok": a.kelompok, "target": v["target"],
                                                         "invariant": inv, "seed": s, "status": st})
                    continue
                kampanye(a.kelompok, v["target"], cwd, JALUR_INV_ACUAN, inv, s, sudah, csv_out)


if __name__ == "__main__":
    main()
