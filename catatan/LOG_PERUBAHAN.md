# Log Perubahan Kode Pengujian

Naskah (Tahap 3): sejak penguncian, kode pengujian hanya diubah pada dua keadaan, dan setiap perubahan dicatat.
Isi tabel ini setiap kali ada perubahan setelah penguncian.

| Tanggal | Commit | Keadaan (1 = pelanggaran palsu kontrak acuan, 2 = pelanggaran pembanding tidak muncul kembali) | Bagian yang diubah | Kampanye yang diulang |
|---|---|---|---|---|

## Penguncian
- Commit penguncian: (diisi akhir Oktober setelah kontrak acuan lulus seed 1 sampai 10)

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
- Belum: commit penguncian setelah proposal disetujui.

- 2026-10-09: folder eksperimen dibuat; versi alat sesuai Tabel 2.4 diperiksa dengan `cek_lingkungan.sh`.
