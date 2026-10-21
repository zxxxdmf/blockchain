import csv
import json
import pathlib
import statistics as st
from collections import defaultdict

AKAR = pathlib.Path(__file__).resolve().parent.parent
OLAHAN = AKAR / "hasil" / "olahan"
ANGGARAN = 256 * 100
SEMUA_SEED = 10
TERPISAH = {"tanpa_pemicu", "gagal_disiapkan"}


def baca(p):
    return list(csv.DictReader(open(p))) if p.exists() else []


def tulis(nama, baris):
    p = OLAHAN / nama
    if not baris:
        p.unlink(missing_ok=True)
        print(f"  {nama}: kosong")
        return
    with open(p, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(baris[0]))
        w.writeheader()
        w.writerows(baris)
    print(f"  {nama}: {len(baris)} baris")


def mmm(nilai):
    if not nilai:
        return "", "", ""
    return round(st.median(nilai), 3), min(nilai), max(nilai)


AKTOR = ["admin", "penerbit", "pemegangA", "pemegangB", "penyerang"]
PEMEGANG = ["pemegangA", "pemegangB"]
PENGGUNA = ["pengguna1", "pengguna2", "pengguna3"]


def terjemahkan(fungsi: str, raw: str) -> str:
    try:
        a = [x.strip() for x in raw.split(",")] if raw else []
        n = [int(x) if x.lstrip("-").isdigit() else x for x in a]
        ak = lambda i: AKTOR[n[i] % 5]
        if fungsi == "terbitkan":
            return f"{ak(0)}.terbitkan(ke {PEMEGANG[n[1] % 2]}, data {n[2] % 10 + 1:03d})"
        if fungsi == "terbitkanUlang":
            return f"{ak(0)}.terbitkanUlang(idLama acak {n[1]}, ke {PEMEGANG[n[2] % 2]})"
        if fungsi == "cabut":
            return f"{ak(0)}.cabut(id acak {n[1]})"
        if fungsi == "transfer":
            return f"{ak(0)}.{'safeTransferFrom' if a[3] == 'true' else 'transferFrom'}(id acak {n[1]}, ke {ak(2)})"
        if fungsi in ("gantiAdmin", "tetapkanPenerbit", "hapusPenerbit"):
            return f"{ak(0)}.{fungsi}({ak(1)})"
        if fungsi == "inisialisasiUlang":
            return f"{ak(0)}.inisialisasi({ak(1)})"
        if fungsi == "verifikasi":
            pilihan = ["hash nomor tercatat", "hash dokumen tercatat", f"hash nomor data {n[1] // 4 % 10 + 1:03d}",
                       "hash lain"][n[1] % 4]
            return f"verifikasi(id acak {n[0]}, {pilihan})"
        if fungsi == "storeDocument":
            h = n[1] % 11
            return (f"{PENGGUNA[n[0] % 3]}.storeDocument({'hash kosong' if h == 10 else f'hash dokumen {h + 1:03d}'}, "
                    f"{'CID kosong' if n[2] % 6 == 5 else f'cid-fiktif-{n[2] % 6}'})")
        if fungsi == "majukanWaktu":
            return "majukanWaktu"
    except (IndexError, ValueError, TypeError):
        pass
    return f"{fungsi}({raw})"


def urutan_shrink(berkas_mentah: str) -> tuple[int | str, str]:
    p = AKAR / berkas_mentah.replace(".json", "_shrink.json")
    if not p.exists():
        return "", ""
    d = json.loads(p.read_text())
    r = next(iter(next(iter(d.values()))["test_results"].values()))
    f = (r.get("invariant_failures") or [{}])[0]
    seq = (f.get("counterexample") or {}).get("Sequence") or []
    langkah = seq[1] if len(seq) == 2 and isinstance(seq[1], list) else seq
    isi = " -> ".join(terjemahkan(c.get("func_name", "?"), c.get("raw_args", "")) for c in langkah)
    return len(langkah), isi


def main():
    kampanye = baca(OLAHAN / "kampanye.csv")
    unit = {b["target"]: b for b in baca(OLAHAN / "unit.csv")}
    meta = {}
    for b in baca(AKAR / "varian" / "terencana" / "daftar.csv"):
        meta[b["kode"]] = {"kelompok": "terencana", "golongan": b["golongan"], "relevan": "ya",
                           "sasaran": b["invariant_sasaran"]}
    for b in baca(AKAR / "varian" / "sistematis" / "daftar.csv"):
        meta[b["id"]] = {"kelompok": "sistematis", "golongan": b["golongan"], "relevan": b["relevan"], "sasaran": ""}

    kontrol = defaultdict(lambda: {"lulus": 0, "jumlah": 0, "pelanggaran": []})
    for b in kampanye:
        if b["kelompok"] == "acuan":
            k = kontrol[b["invariant"]]
            k["jumlah"] += 1
            k["lulus"] += b["status"] == "lulus"
            if b["status"] != "lulus":
                k["pelanggaran"].append(f"seed {b['seed']}: {b['status']} {b['alasan'][:80]}")
    tulis("kontrol_acuan.csv", [{"invariant": i, "seed_lulus": k["lulus"], "seed_dijalankan": k["jumlah"],
                                 "catatan": " | ".join(k["pelanggaran"])} for i, k in sorted(kontrol.items())])
    if any(k["pelanggaran"] for k in kontrol.values()):
        print("  PERINGATAN: kontrak acuan melanggar invariant -> periksa invariant/handler (pelanggaran palsu)")

    per_seed = defaultdict(lambda: defaultdict(list))
    status_varian = defaultdict(set)
    for b in kampanye:
        if b["kelompok"] in ("terencana", "sistematis"):
            status_varian[b["target"]].add(b["status"])
            if b["status"] == "terdeteksi":
                per_seed[b["target"]][int(b["seed"])].append(b)

    ringkasan = []
    for target, m in meta.items():
        seeds = per_seed.get(target, {})
        calls, durasi, shrink = [], [], []
        for baris in seeds.values():
            cepat = min(baris, key=lambda r: int(r["calls"]))
            calls.append(int(cepat["calls"]))
            durasi.append(float(cepat["durasi_ms"]))
            if cepat["panjang_urutan_shrink"]:
                shrink.append(int(cepat["panjang_urutan_shrink"]))
        c_med, c_min, c_max = mmm(calls)
        d_med, d_min, d_max = mmm(durasi)
        cocok = ""
        if shrink and m["golongan"] in ("1", ">1"):
            cocok = "ya" if (min(shrink) == 1) == (m["golongan"] == "1") else "tidak"
        ringkasan.append({
            "target": target, "kelompok": m["kelompok"], "invariant_sasaran": m["sasaran"], "relevan": m["relevan"],
            "golongan": m["golongan"], "perhitungan": "terpisah" if m["golongan"] in TERPISAH else "utama",
            "seed_mendeteksi": len(seeds), "dari_seed": SEMUA_SEED,
            "calls_median": c_med, "calls_min": c_min, "calls_maks": c_max,
            "persen_anggaran_median": round(100 * c_med / ANGGARAN, 3) if calls else "",
            "durasi_ms_median": d_med, "durasi_ms_min": d_min, "durasi_ms_maks": d_max,
            "panjang_shrink_min": min(shrink) if shrink else "", "panjang_shrink_median": mmm(shrink)[0],
            "shrink_cocok_golongan": cocok,
            "status_lain": ";".join(sorted(status_varian[target] - {"lulus", "terdeteksi"})),
            "unit_test": unit.get(target, {}).get("status", ""),
            "unit_tes_gagal": unit.get(target, {}).get("tes_gagal", ""),
        })
    tulis("ringkasan_varian.csv", ringkasan)
    tulis("varian_terpisah.csv", [r for r in ringkasan if r["perhitungan"] == "terpisah"])
    utama = [r for r in ringkasan if r["perhitungan"] == "utama"]

    eff = []
    for kel, versi in (("terencana", "semua"), ("sistematis", "semua"), ("sistematis", "relevan")):
        anggota = [r["target"] for r in utama if r["kelompok"] == kel and (versi == "semua" or r["relevan"] == "ya")]
        for s in range(1, SEMUA_SEED + 1):
            n = sum(1 for t in anggota if s in per_seed.get(t, {}))
            eff.append({"kelompok": kel, "versi": versi, "seed": s, "varian_terdeteksi": n, "varian_lolos": len(anggota) - n,
                        "jumlah_varian": len(anggota)})
    tulis("efektivitas_per_seed.csv", eff)

    banding = []
    for kel, versi in (("terencana", "semua"), ("sistematis", "semua"), ("sistematis", "relevan")):
        for gol in ("1", ">1"):
            for kriteria in ("10_seed", "minimal_1_seed"):
                hit = defaultdict(int)
                for r in utama:
                    if r["kelompok"] != kel or r["golongan"] != gol or (versi == "relevan" and r["relevan"] != "ya"):
                        continue
                    sf = r["seed_mendeteksi"] == SEMUA_SEED if kriteria == "10_seed" else r["seed_mendeteksi"] >= 1
                    ut = r["unit_test"] == "terdeteksi"
                    hit["kedua_cara" if sf and ut else "hanya_stateful_fuzzing" if sf else "hanya_unit_test" if ut
                        else "tidak_terdeteksi"] += 1
                banding.append({"kelompok": kel, "versi": versi, "golongan": gol, "kriteria": kriteria,
                                "kedua_cara": hit["kedua_cara"], "hanya_stateful_fuzzing": hit["hanya_stateful_fuzzing"],
                                "hanya_unit_test": hit["hanya_unit_test"], "tidak_terdeteksi": hit["tidak_terdeteksi"]})
    tulis("perbandingan_golongan.csv", banding)

    cpg = []
    for kel in ("terencana", "sistematis"):
        for gol in ("1", ">1"):
            nilai = [r["calls_median"] for r in utama if r["kelompok"] == kel and r["golongan"] == gol and r["calls_median"] != ""]
            med, mn, mx = mmm(nilai)
            cpg.append({"kelompok": kel, "golongan": gol, "varian_terdeteksi": len(nilai),
                        "median_dari_median_calls": med, "min": mn, "maks": mx,
                        "persen_anggaran_median": round(100 * med / ANGGARAN, 3) if nilai else ""})
    tulis("calls_per_golongan.csv", cpg)

    langgar = []
    for b in kampanye:
        if b["status"] != "terdeteksi":
            continue
        panjang, isi = urutan_shrink(b["berkas_mentah"])
        langgar.append({"kelompok": b["kelompok"], "kontrak": b["target"], "invariant": b["invariant"], "seed": b["seed"],
                        "golongan": meta.get(b["target"], {}).get("golongan", ""), "alasan": b["alasan"],
                        "panjang_awal": b["panjang_urutan_awal"], "panjang_shrink": panjang, "urutan_shrink": isi})
    tulis("pelanggaran.csv", langgar)

    tulis("pembanding.csv", [b for b in kampanye if b["kelompok"] == "pembanding"])


if __name__ == "__main__":
    main()
