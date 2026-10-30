# Catatan Eksekusi Tahap 7

- kode: commit 848d48d (tag penguncian); forge 1.8.3, solc 0.8.37 (EVM osaka)
- jaringan: Sepolia (chain 11155111), RPC Infura
- akun penerbit (admin dan penerbit): 0x26370dBF1D2baB596C9Bcc4121312c7c94e7EaCc
- akun pemegang A: 0x78e53085306511926Db871898E23d9f02f818bbd (diisi 0,05 ETH Sepolia dari akun penerbit, 2026-10-30)

## Deploy
- percobaan 1 (2026-10-30 10:51, log deploy_sepolia_20261030_105144.log): GAGAL. Transaksi pembuatan kontrak
  0xb684a47ab45a1bc7b98a13d1f0bcae58368ef15d5df635f918fb97e7f844566f kehabisan gas (batas 3.956.998 terpakai
  seluruhnya). Batas gas berasal dari simulasi lokal forge (sekitar 3,04 juta gas x 1,3), sedangkan Sepolia memungut
  biaya penyimpanan kode yang lebih tinggi. Dua panggilan berikutnya (inisialisasi, tetapkanPenerbit) masuk ke
  alamat kosong 0xc0c7B8E39524a65f78000b839748635FfA8EC24e tanpa dampak. Tidak ada kontrak yang terbentuk.
- percobaan 2 (2026-10-30 11:15): berhenti di simulasi karena galat sementara RPC (block not found); tidak ada
  transaksi terkirim.
- percobaan 2b (2026-10-30 11:20, log deploy_sepolia_20261030_112013.log): sandi keystore salah; berhenti sebelum
  transaksi apa pun terkirim.
- percobaan 3 (2026-10-30 11:21, log deploy_sepolia_20261030_112121.log): BERHASIL, dengan
  --gas-estimate-multiplier 1000. Kode yang dikunci tidak berubah.
  - kontrak: 0xcE5b35c89c749De5AD245C15ea9016951d1156F3, blok 12023966
  - buat kontrak: 0x287d981f913f3c6e65e86ecbf92e86e8d10f88f3493b7911e94e56004a8ed306 (gas 21.458.513)
  - inisialisasi: 0x5f8ec473a785fa2fe5c546eea98e6783f844dca65da78641d21531b7aad1d9bd (gas 239.451)
  - tetapkanPenerbit: 0x60a7739fc1da2fc8b2a73ec6e84c174169516a66683939d815bf840a5f386e1a (gas 131.118)
  - pemeriksaan: sudahDiinisialisasi true, admin = penerbit, peran PENERBIT true, idBerikutnya 1
  - bytecode di Sepolia identik dengan hasil kompilasi lokal kode yang dikunci
  - kode sumber terverifikasi di Etherscan (Pass - Verified) dan dikirim ke Sourcify
- pembanding: deploy yang sama di Anvil memakai 3.043.845 gas untuk pembuatan kontrak.

## Penyiapan data jalur QR code
- percobaan 1 (2026-10-30 12:49, log siapkan_data_20261030_124917.log): berhenti sebelum transaksi pertama. Skrip
  pembungkus di luar repositori menghapus berkas sandi keystore terlalu dini, sehingga `cast send` untuk
  terbitkan A gagal. Tidak ada transaksi terkirim (nonce penerbit tetap 7, idBerikutnya tetap 1). A_aktif.pdf yang
  sudah terbentuk dihapus agar penyiapan dijalankan dari awal; isinya ditentukan oleh ID token 1 dan dibuat ulang
  identik. Kode di repositori tidak berubah.
- percobaan 2 (2026-10-30 12:52, log siapkan_data_20261030_125212.log): BERHASIL. Enam transaksi status 1:
  terbitkan A (token 1) 0xf10e1d28fd6266f14c7bd393708d8ac5c4e1f27b3858ad0bf15f80ec1915b546,
  terbitkan B (token 2) 0x4db2ff9e509d62066260395c1dd5d28d7b9670137d8bd2e3805e082f6a0d52e4,
  terbitkan C (token 3) 0x4662d6c65310164a6764a9723458ea61e2c3701dac6233aa4ef944f1dc171a14,
  cabut B 0xf24c6ab316f6ab140478f47dd9484ce72df2bfbbcf509831f23ddc9fa7ba71e7,
  cabut C 0x007a2e78028605cd57e592358814c88869272886ad3ce388b79d9dc115d172a2,
  terbitkanUlang C (token 3 -> 4) 0x102c952012ba5890b97b39cce7c1335673bd53b4ab73859c6dc323a22d1c9fe0.
  Pemeriksaan: idBerikutnya 5; hash nomor dan hash PDF token 1 sampai 4 di kontrak sama dengan berkas dan
  manifest.json; token 2 dan 3 dicabut, token 1 dan 4 aktif.

## Uji penolakan (2026-10-30 12:55, log uji_penolakan_20261030_125558.log)
- transfer token A oleh pemiliknya: status 0, 0x92911ce5260d83d1253244796b6d73218151328b4cec68c017c8af2d0632a4fc,
  blok 12024427, gas 21.400 dari batas 200.000; alasan TokenTerkunci (0xaa83eb00)
- penerbitan oleh alamat tanpa peran: status 0, 0xd9821630e94fb3f1edc57fa814df1409935ba33aee48238ab5f29f16f09a0a6c,
  blok 12024428, gas 21.400 dari batas 300.000; alasan BukanPenerbit (0x0b6f447f)
- alasan diperoleh dengan memanggil ulang kedua panggilan tanpa transaksi pada blok 12024426; pemakaian gas jauh di
  bawah batas, jadi penolakan bukan karena kehabisan gas. Pemilik token 1 tetap akun pemegang A.

## Pengujian dari iPhone 15 (2026-10-30 20.02 sampai 20.23 WITA)
- 13 pemeriksaan Tabel 2.8 dijalankan dari Safari iPhone 15 di halaman https://zxxxdmf.github.io/blockchain/halaman/;
  QR code dipindai dari layar laptop (Quick Look), berkas PDF diunggah dari aplikasi File.
- Tangkapan layar di hasil/olahan/qr_tangkapan_layar/ (nama K<kasus>_<masukan>.png; asal dan waktu di daftar.csv).
- Hasil halaman: 13 dari 13 sesuai dengan hasil yang diharapkan dan dengan hasil cast (cek_kasus.py,
  hasil/olahan/qr_kasus.csv). Kode hasil kontrak, ID token, dan hash di layar sama dengan hasil cast.
- Kejadian di luar rencana:
  - K6_nomor: percobaan pertama salah ketik (IJZ-2026-105, tanpa FIKTIF), hasil PALSU kode 0; dijalankan ulang
    dengan nomor yang benar, hasil PALSU kode 0. Yang dipakai adalah percobaan dengan nomor yang benar.
  - K5_nomor terlewat pada urutan awal, lalu dijalankan sekali setelah K7_pdf (20.23).
  - Dua berkas di iPhone bernama "A_aktif 2.pdf" dan "D7_nama_diubah 2.pdf" (akhiran dari aplikasi File); hash di
    layar sama dengan hash berkas asli, jadi isinya tidak berubah.

## Arsip data mentah Tahap 7
- hasil/mentah tidak di-commit. Sembilan berkas Tahap 7 (empat log deploy, dua log penyiapan data, log uji
  penolakan, qr_transaksi.csv, qr_penolakan.csv) diarsipkan ke mentah_tahap7_2026-10-30.tar.gz (3600 byte),
  sha256 acf98303673899a57b32f0ea98a013f9e62efa83961ea4ba394a89346ca21f15.
