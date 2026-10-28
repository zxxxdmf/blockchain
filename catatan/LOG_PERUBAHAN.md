# Log Perubahan Kode Pengujian

Naskah (Tahap 3): sejak penguncian, kode pengujian hanya diubah pada dua keadaan, dan setiap perubahan dicatat.
Isi tabel ini setiap kali ada perubahan setelah penguncian.

| Tanggal | Commit | Keadaan (1 = pelanggaran palsu kontrak acuan, 2 = pelanggaran pembanding tidak muncul kembali) | Bagian yang diubah | Kampanye yang diulang |
|---|---|---|---|---|

## Penguncian
- 2026-10-28: commit penguncian adalah commit bertag `penguncian`. Kode pengujian di dalamnya sama dengan commit
  5132b57, yang lulus kontrol pra-penguncian 2026-10-21 (I1..I7 x seed 1..10 = 70/70, unit test 35/35, Anvil 31/31).
  Proposal telah disetujui dan tidak ada catatan penguji yang mengubah kode. Pemeriksaan ulang lingkungan pada
  2026-10-28 dengan `cek_lingkungan.sh`: versi perangkat lunak sesuai Tabel 2.4 (24 OK; 4 KURANG hanya konfigurasi
  Sepolia untuk Tahap 7, yaitu .env, keystore penerbit, dan halaman/config.js, yang bukan kode pengujian).
- Sejak commit ini, kode pengujian hanya diubah pada dua keadaan di atas. Lingkungan dibekukan sampai eksekusi
  selesai: tanpa `foundryup`, `brew upgrade`, pembaruan macOS, atau `forge fmt`.

## Persiapan (sebelum penguncian)
- 2026-10-09: kode penelitian ditulis (kontrak acuan, unit test, handler + I1..I7, K1..K5, generator varian, otomasi,
  jalur QR code, halaman verifikasi). Uji coba alat: kontrol lulus I1..I7 seed 1..3; C1..C9 terdeteksi pada invariant
  sasarannya seed 1..3; K1..K5 lulus seed 1..2; gladi Tahap 7 di Anvil lulus.
- 2026-10-09: perbaikan handler sebelum penguncian: (1) panggilan eksternal di antara vm.prank dan cabut dipindah
  sebelum prank (sebelumnya cabut selalu gagal); (2) catatan bayangan pencabutan hanya untuk token yang sudah ada.
- 2026-10-09: unit test sudah dijalankan pada semua varian dan stateful fuzzing pada beberapa varian sistematis sebagai
  uji coba alat. Setelah melihat hasil itu, NILAI golongan tidak diubah; yang diperjelas hanya alasan S02H dan S16H serta
  definisi tanpa pemicu (perubahan jenis galat saja) dan golongan baru gagal_disiapkan (S01B, S02B), sesuai naskah
  Tahap 4 revisi 2026-10-09. Unit test tidak ditambah setelah terlihat C8 dan S23H lolos.
- 2026-10-09: kontrol pra-penguncian (I1..I7 x seed 1..10) disimpan di hasil/pra_penguncian/2026-10-09/.
- 2026-10-10: penulis menyetujui seluruh golongan di varian/sistematis/usulan_golongan.csv tanpa perubahan
  (dalam rangka uji coba lokal; S05B dan S06B kemudian dikoreksi 2026-10-11, lihat entri di bawah).
- 2026-10-11: koreksi golongan S05B dan S06B dari 1 menjadi gagal_disiapkan. Uji coba lokal menunjukkan setUp gagal
  pada 70 dari 70 kampanye (BukanAdmin, AlamatNol) karena setUp memanggil tetapkanPenerbit; analisis usulan
  melewatkan panggilan ini. Koreksi didasarkan pada kegagalan setUp sesuai definisi Tahap 4, bukan pada hasil deteksi.
- 2026-10-21: komentar dibersihkan dari seluruh kode (src, test, script, otomasi, jalur_qr, halaman, uji_alat,
  varian/buat_varian.py, foundry.toml, .gitignore, .env.example, requirements.txt), sebelum penguncian. Yang
  dipertahankan: baris SPDX dan shebang. Pengecualian lint unsafe-oz-erc721-mint dipindah ke [lint] di foundry.toml.
  Generator varian tidak lagi menyisipkan komentar; varian dibangkitkan ulang. Bukti perilaku tidak berubah:
  bytecode dan ABI tanpa metadata identik untuk 58 kontrak (acuan + 57 varian) dan seluruh artefak forge; AST Python
  identik (di luar docstring); unit test 33/33; cek_lingkungan.sh 23 OK; kontrol seed 1 (I1..I7, C1..C9, K1..K5)
  identik dengan uji coba 2026-10-10 pada status, calls, dan panjang shrink. daftar.csv sistematis hanya berubah
  pada kolom baris (nomor baris acuan bergeser, mis. S01 71 -> 57, S24 178 -> 148); ID, relevan, golongan tetap.
  Versi berkomentar disimpan di luar repo: ../eksperimen_berkomentar/ (bahan belajar penulis).
- 2026-10-21: dua kasus unit test ditambahkan, test_grantRole_P dan test_revokeRole_P, agar templat kategori alamat
  tanpa peran berlaku untuk ketiga fungsi peran bawaan yang dinonaktifkan (sebelumnya hanya renounceRole). Kedua
  fungsi itu tidak memiliki baris pemeriksaan yang dimutasi, sehingga hasil unit test pada 57 varian tidak berubah
  (dibandingkan dengan uji coba 2026-10-10: status dan daftar kasus gagal identik). Kontrol negatif: tanpa
  penonaktifan, kedua kasus gagal. Unit test kontrak acuan kini 35 kasus.
- 2026-10-21: kontrol pra-penguncian diulang, I1..I7 x seed 1..10 = 70/70 lulus, unit test 35/35, Anvil 31/31
  (hasil/pra_penguncian/2026-10-21/).

- 2026-10-09: folder eksperimen dibuat; versi alat sesuai Tabel 2.4 diperiksa dengan `cek_lingkungan.sh`.
