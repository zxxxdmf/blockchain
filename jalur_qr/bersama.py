import json
import os
import pathlib
import subprocess

import qrcode
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

AKAR = pathlib.Path(__file__).resolve().parent.parent
DOKUMEN = AKAR / "jalur_qr" / "dokumen"
KATEGORI = {0: "palsu", 1: "palsu", 2: "tidak berlaku", 3: "asli"}


def baca_env() -> dict:
    env = {}
    p = AKAR / ".env"
    if p.exists():
        for baris in p.read_text().splitlines():
            if "=" in baris and not baris.lstrip().startswith("#"):
                k, v = baris.split("=", 1)
                env[k.strip()] = v.strip()
    return env


class Cast:

    def __init__(self, rpc: str, kontrak: str = "", kunci: str = "", akun: str = "", sandi_file: str = ""):
        self.rpc, self.kontrak = rpc, kontrak
        self.tanda = (["--private-key", kunci] if kunci else ["--account", akun] if akun else [])
        if sandi_file:
            self.tanda += ["--password-file", sandi_file]

    def _jalankan(self, args: list[str]) -> str:
        p = subprocess.run(["cast", *args], capture_output=True, text=True)
        if p.returncode != 0:
            raise RuntimeError(f"cast {' '.join(args[:2])} gagal: {p.stderr.strip()[-400:]}")
        return p.stdout.strip()

    def call(self, sig: str, *arg: str) -> str:
        return self._jalankan(["call", self.kontrak, sig, *arg, "--rpc-url", self.rpc])

    def send(self, sig: str, *arg: str, gas_limit: int | None = None, tanda: list[str] | None = None) -> dict:
        args = ["send", self.kontrak, sig, *arg, "--rpc-url", self.rpc, "--json", *(tanda or self.tanda)]
        if gas_limit:
            args += ["--gas-limit", str(gas_limit)]
        r = json.loads(self._jalankan(args))
        return {"tx": r["transactionHash"], "status": int(r["status"], 16), "blok": int(r["blockNumber"], 16)}


def keccak_teks(teks: str) -> str:
    return subprocess.run(["cast", "keccak", teks], capture_output=True, text=True, check=True).stdout.strip()


def keccak_berkas(p: pathlib.Path) -> str:
    return subprocess.run(["cast", "keccak", "0x" + p.read_bytes().hex()], capture_output=True, text=True,
                          check=True).stdout.strip()


def seragamkan(nomor: str) -> str:
    return nomor.strip().upper()


def buat_pdf(nama_berkas: str, nomor: str, nama: str, tautan_qr: str) -> pathlib.Path:
    DOKUMEN.mkdir(parents=True, exist_ok=True)
    p = DOKUMEN / nama_berkas
    c = canvas.Canvas(str(p), pagesize=A4, invariant=1)
    lebar, tinggi = A4
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(lebar / 2, tinggi - 90, "IJAZAH FIKTIF - UNTUK PENELITIAN")
    c.setFont("Helvetica", 10)
    c.drawCentredString(lebar / 2, tinggi - 108, "Bukan dokumen resmi. Dibuat untuk pengujian verifikasi berbasis Soulbound Token.")
    c.setFont("Helvetica", 13)
    c.drawString(80, tinggi - 170, f"Nomor ijazah : {nomor}")
    c.drawString(80, tinggi - 195, f"Nama         : {nama}")
    c.drawString(80, tinggi - 220, "Program studi: Program Studi Fiktif")
    qr = qrcode.make(tautan_qr, border=2).get_image()
    c.drawImage(ImageReader(qr), lebar - 230, tinggi - 420, 150, 150)
    c.setFont("Helvetica", 8)
    c.drawString(lebar - 230, tinggi - 432, "Pindai untuk verifikasi")
    c.save()
    return p


def tautan(url_halaman: str, id_token: int) -> str:
    return f"{url_halaman.rstrip('/')}/?token={id_token}"


def alamat_dari_teks(teks: str) -> str:
    return "0x" + keccak_teks(teks)[-40:]


def env_atau(nama: str, bawaan: str = "") -> str:
    return os.environ.get(nama) or baca_env().get(nama, bawaan)
