# Varian kontrak dengan cacat sisipan (Tahap 4)

Bangkitkan ulang setelah kontrak acuan berubah: `.venv/bin/python -I varian/buat_varian.py`.

- `terencana/C1..C9`: Tabel 2.6, masing-masing satu perubahan; `terencana/daftar.csv` memuat invariant sasaran dan golongan.
- `sistematis/S..H` (hapus pemeriksaan) dan `S..B` (balik kondisi): satu varian per baris pemeriksaan
  `if (...) revert ...;` atau `if (...) return Hasil...;` di `src/IjazahSBT.sol`, ditemukan otomatis.
- `sistematis/usulan_golongan.csv`: USULAN relevan dan golongan dari analisis kode, disalin ke `daftar.csv`
  oleh generator. **Wajib ditinjau penulis dan di-commit sebelum eksekusi; tidak diubah sesudahnya.**

## Definisi yang dipakai dalam usulan (sama dengan naskah Tahap 4, revisi 2026-10-09)
- **relevan**: perubahan menyangkut salah satu aturan pada kolom Invariant Tabel 2.1 (peran penerbit/admin,
  penguncian, pencabutan, penerbitan ulang, satu token aktif per data, hasil verifikasi). Pemeriksaan alamat
  nol dan hash kosong tidak termasuk.
- **1 / >1**: jumlah transaksi minimum untuk memicu cacat dari keadaan awal `setUp` kampanye invariant.
- **tanpa_pemicu**: varian yang tidak mengubah perilaku kontrak terhadap aturan pada Tabel 2.1, yaitu diterima
  atau ditolaknya panggilan dari keadaan awal `setUp` beserta keadaan kontrak sesudahnya. Mencakup varian yang
  hanya mengubah jenis galat (S09H, S16H, S17H, S19H), walaupun unit test dapat menggagalkannya karena memeriksa
  selector galat (S16H); juga S02H, yang tidak terjangkau dari `setUp` tetapi digagalkan unit test yang men-deploy
  kontrak baru.
- **gagal_disiapkan**: varian yang membuat `setUp` gagal (S01B, S02B, S05B, S06B; dua yang terakhir dikoreksi
  2026-10-11, lihat `catatan/LOG_PERUBAHAN.md`).
- tanpa_pemicu dan gagal_disiapkan disajikan dalam tabel tersendiri (`hasil/olahan/varian_terpisah.csv`),
  terpisah dari jumlah varian terdeteksi dan dari perbandingan per golongan.
- Klaim di atas diuji langsung pada 2026-10-09: S01B dan S02B gagal pada setUp; S02H, S09H, S16H, S17H, S19H tetap
  menolak panggilan yang sama dari keadaan setUp.
