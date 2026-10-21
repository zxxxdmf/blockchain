import pathlib, subprocess, tempfile
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader

AKAR = pathlib.Path(__file__).resolve().parent.parent
TAUTAN = "https://contoh.github.io/verifikasi/?token=1"


def buat_pdf(jalur, nomor, nama):
    gambar = qrcode.make(TAUTAN).get_image()
    c = canvas.Canvas(str(jalur), invariant=1)
    c.drawString(72, 760, "IJAZAH FIKTIF - UNTUK PENELITIAN")
    c.drawString(72, 740, f"Nomor: {nomor}")
    c.drawString(72, 720, f"Nama: {nama}")
    c.drawImage(ImageReader(gambar), 72, 560, 140, 140)
    c.save()


def cast_keccak_berkas(p):
    return subprocess.run(["cast", "keccak", "0x" + p.read_bytes().hex()], capture_output=True, text=True, check=True).stdout.strip()


def cast_keccak_teks(t):
    return subprocess.run(["cast", "keccak", t], capture_output=True, text=True, check=True).stdout.strip()


def ethers(jenis, nilai):
    return subprocess.run(["node", str(AKAR / "uji_alat/keccak_ethers.mjs"), jenis, nilai], capture_output=True,
                          text=True, check=True, cwd=AKAR).stdout.strip()


seragam = lambda n: n.strip().upper()
ok = True
with tempfile.TemporaryDirectory() as d:
    a, b = pathlib.Path(d, "a.pdf"), pathlib.Path(d, "b.pdf")
    buat_pdf(a, "IJZ-FIKTIF-2026-001", "Mahasiswa Fiktif A")
    buat_pdf(b, "IJZ-FIKTIF-2026-001", "Mahasiswa Fiktif A")
    sama = a.read_bytes() == b.read_bytes()
    print(f"PDF dibuat ulang identik (invariant=1): {sama}"); ok &= sama
    hc, he = cast_keccak_berkas(a), ethers("berkas", str(a))
    print(f"keccak berkas PDF  cast={hc[:18]}... ethers={he[:18]}... sama={hc == he}"); ok &= hc == he
    nomor = seragam("  ijz-fiktif-2026-001 ")
    nc, ne = cast_keccak_teks(nomor), ethers("teks", nomor)
    print(f"keccak nomor '{nomor}' cast={nc[:18]}... ethers={ne[:18]}... sama={nc == ne}"); ok &= nc == ne
    c = pathlib.Path(d, "c.pdf"); buat_pdf(c, "IJZ-FIKTIF-2026-001", "Mahasiswa Fiktif B")
    beda = cast_keccak_berkas(c) != hc
    print(f"PDF dengan nama diubah menghasilkan hash berbeda (kasus 7): {beda}"); ok &= beda
print("HASIL:", "LULUS" if ok else "GAGAL")
