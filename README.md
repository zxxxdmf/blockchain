# Eksperimen: Verifikasi Keaslian Ijazah Berbasis Soulbound Token dengan Stateful Fuzzing

Repositori kode penelitian. Isi dan urutan kerja mengikuti BAB II naskah proposal
(`PROPOSAL HASIL/DRAFT-PROPOSAL-HASIL_REVISI-<tanggal>.docx`). Data dan dokumen ijazah di sini fiktif.

## Peta folder terhadap prosedur (subbab 2.3)

| Folder | Isi | Tahap |
|---|---|---|
| `src/` | kontrak acuan (ERC-721 + ERC-5192, pencabutan, penerbitan ulang, verifikasi) | 2 |
| `src/pembanding/` | `DocumentVerification.sol` (Bimantoro et al., 2026), disalin tanpa perubahan | 2 |
| `test/acuan/unit/` | unit test berskenario tetap (templat: berhasil, data tidak valid, data ganda, data tidak dikenal, alamat tanpa peran) | 2 |
| `test/acuan/invariant/` | invariant test I1 sampai I7 dan handler kontrak acuan | 3 |
| `test/pembanding/` | invariant K1 sampai K5, handler, dan uji ulang langsung tanpa handler | 3, 6 |
| `varian/terencana/` | C1 sampai C9 (Tabel 2.6) | 4 |
| `varian/sistematis/` | varian hasil mutasi (hapus pemeriksaan, balik kondisi) beserta golongan relevan dan jumlah transaksi | 4 |
| `otomasi/` | skrip Python yang menjalankan setiap kampanye berurutan dan mencatat hasilnya | 5 |
| `hasil/mentah/` | keluaran forge apa adanya per kampanye | 5, 6 |
| `hasil/olahan/` | tabel deteksi, calls, waktu, urutan pemicu (`otomasi/ringkas.py`) | 6, 8 |
| `hasil/pra_penguncian/` | kontrol kontrak acuan sebelum penguncian (bukan hasil Tahap 5) | 3 |
| `script/` | skrip forge deploy dan inisialisasi (Sepolia dan Anvil); `cek_aturan_anvil.sh` memeriksa aturan Tabel 2.1 melalui cast di Anvil | 2, 7 |
| `jalur_qr/` | skrip penyiapan data jalur QR code; `dokumen/` berisi tujuh PDF (A, B, C lama, C pengganti, D5, D6, D7) dan manifest.json | 7 |
| `halaman/` | halaman verifikasi untuk GitHub Pages: `index.html` (tampilan), `verifikasi.js` (logika, dipakai juga oleh uji Node `uji_logika.js`), `config.js` (alamat kontrak dan RPC), `vendor/` (ethers.js 6.17.0) | 7 |
| `catatan/` | panduan eksekusi dan log perubahan setelah penguncian | 3 sampai 8 |
| `uji_alat/` | uji rantai alat, BUKAN bagian penelitian | - |

## Versi (Tabel 2.4)

Foundry 1.8.3, solc 0.8.37, OpenZeppelin Contracts v5.7.0, forge-std v1.17.0 (terkunci di `foundry.lock`),
Python 3.14.7 dengan qrcode 8.2, Pillow 12.3.0, reportlab 5.0.1 (`requirements.txt`, lingkungan `.venv/`),
ethers.js 6.17.0 (`package.json`). Periksa semuanya dengan:

```
./cek_lingkungan.sh
```

## Menyiapkan ulang di komputer lain

```
forge install            # pustaka sesuai foundry.lock
python3.14 -m venv .venv && .venv/bin/pip install -r requirements.txt
npm install
cp .env.example .env     # isi SEPOLIA_RPC_URL, ETHERSCAN_API_KEY, AKUN_DEPLOY, ALAMAT_DEPLOY
```

`.env` dan kunci tidak pernah di-commit. Akun deploy disimpan sebagai keystore terenkripsi Foundry.
