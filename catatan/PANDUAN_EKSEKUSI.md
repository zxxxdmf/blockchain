# Panduan Eksekusi (Tahap 5 sampai 7)

Aturan di bawah diturunkan dari naskah dan dari uji coba alat. Ikuti persis agar hasil dapat diulang.

## Satu kampanye stateful fuzzing
- Satu kampanye = satu invariant x satu kontrak (acuan, varian, atau pembanding) x satu seed.
- Seed 1 sampai 10: `--fuzz-seed <n>`.
- **Hapus `cache/invariant` sebelum setiap kampanye.** Foundry memutar ulang kegagalan yang tersimpan,
  sehingga tanpa penghapusan hasil seed berikutnya hanya mengulang kegagalan lama (uji coba 2026-10-04).
- Eksekusi pertama tanpa shrinking: `FOUNDRY_INVARIANT_SHRINK_RUN_LIMIT=0`. Catat status terdeteksi, `calls`,
  dan durasi. Waktu dengan shrinking didominasi shrinking (sekitar 95% pada uji coba).
- Bila terdeteksi, jalankan sekali lagi dengan shrinking bawaan untuk urutan terpendek (`[Sequence] (original: N, shrunk: M)`).
- Konfigurasi tetap di `foundry.toml`: runs 256, depth 100, check_interval 1, fail_on_revert false, workers 1.
  Uji alat 2026-10-09: calls per seed identik untuk workers auto maupun 1; workers 1 dipilih agar durasi tidak
  dipengaruhi paralelisme.

## Urutan kerja (perintah)
```
./cek_lingkungan.sh                                         # alat lengkap
forge test --match-path 'test/acuan/unit/*'                 # Tahap 2: kontrak acuan lulus unit test
./script/cek_aturan_anvil.sh                                # Tahap 2: deploy ke Anvil + aturan Tabel 2.1 melalui cast
.venv/bin/python -I otomasi/jalankan.py acuan               # Tahap 3/5: kontrol I1..I7 x seed 1..10, harus lulus semua
# -> tinjau varian/sistematis/daftar.csv, lalu COMMIT PENGUNCIAN (catat di LOG_PERUBAHAN.md)
.venv/bin/python -I varian/buat_varian.py                   # Tahap 4 (jalankan ulang hanya bila kontrak acuan berubah sebelum penguncian)
.venv/bin/python -I otomasi/jalankan.py terencana           # Tahap 5: 9 varian x invariant sasaran x 10 seed
.venv/bin/python -I otomasi/jalankan.py sistematis          # Tahap 5: 48 varian x 7 invariant x 10 seed
.venv/bin/python -I otomasi/jalankan.py pembanding          # Tahap 5: K1..K5 x 10 seed
.venv/bin/python -I otomasi/jalankan.py unit                # Tahap 5: unit test sekali per varian
.venv/bin/python -I otomasi/ringkas.py                      # Tahap 6/8: tabel ringkasan di hasil/olahan
./jalur_qr/gladi_anvil.sh                                   # gladi Tahap 7 di Anvil (berkas dihapus otomatis)
```
Skrip otomasi melanjutkan dari hasil yang sudah tercatat bila terputus (`--ulang` untuk mengabaikannya).

## Hal yang ditemukan saat menyiapkan kode (2026-10-09)
- `--match-test` dicocokkan dengan nama lengkap termasuk `()`: pakai `'^invariant_I1\(\)$'` (sudah di skrip).
- Jangan menaruh panggilan eksternal di antara `vm.prank` dan panggilan sasaran di handler: prank terpakai
  oleh panggilan itu (sempat membuat cabut selalu gagal; sudah diperbaiki).
- Variabel bayangan pencabutan hanya dicatat untuk token yang sudah ada (mencegah pelanggaran semu pada S13H).
- Panjang urutan hasil shrinking adalah batas atas, belum tentu minimum: shrinking hanya membuang panggilan dari
  urutan yang gagal (contoh C1 seed 1: panjang 1 atau 2 tergantung urutan asal). Laporkan apa adanya (Tahap 6).
- Setelah commit penguncian, kode tidak boleh diubah sama sekali, termasuk `forge fmt`: perubahan bytecode
  (metadata) dapat menggeser nilai acak yang dibangkitkan untuk seed yang sama.
- Uji coba 2026-10-09: kontrol lulus (I1..I7, seed 1..3); C1..C9 terdeteksi pada invariant sasarannya (seed 1..3);
  K1..K5 lulus (seed 1..2); unit test tidak mendeteksi C8 dan S23H (akibat templat tetap; jangan menambah kasus
  setelah melihat hasil ini). Durasi kampanye 1,6 sampai 21 detik (K4 dan K5 sekitar 17 sampai 21 detik).

## Varian
- Varian terencana hanya dijalankan pada invariant sasarannya (Tabel 2.6); varian sistematis pada ketujuh invariant.
- Golongan relevan dan golongan jumlah transaksi ditetapkan dan di-commit SEBELUM eksekusi; tidak diubah sesudahnya.
- Unit test dijalankan sekali per varian (deterministik).

## Kontrak pembanding
- Setiap urutan pelanggaran K1 sampai K5 dijalankan ulang langsung ke kontrak tanpa handler. Pelanggaran hanya
  dilaporkan bila muncul kembali; bila tidak, perbaiki handler, ulangi kampanye, catat di `LOG_PERUBAHAN.md`.

## Penguncian (akhir Tahap 3)
- Setelah kontrak acuan lulus semua invariant pada seed 1 sampai 10: commit seluruh invariant, handler, dan unit
  test, termasuk milik kontrak pembanding. Catat kode commit di `LOG_PERUBAHAN.md` dan publikasikan repositori.
- Sesudahnya kode pengujian hanya boleh diubah pada dua keadaan di naskah (pelanggaran palsu pada kontrak acuan;
  pelanggaran kontrak pembanding yang tidak muncul kembali). Setiap perubahan dicatat.

## Jalur QR code (Tahap 7)
- PDF dibuat dengan reportlab `Canvas(..., invariant=1)` (tanpa itu CreationDate membuat hash berubah setiap
  dibuat ulang). Jangan menyebut "mode invariant" di naskah karena bentrok dengan istilah invariant I1 sampai I7.
- Tujuh berkas (A, B, C lama, C pengganti, D5, D6, D7) disimpan apa adanya di `jalur_qr/dokumen/` beserta hash keccak256-nya.
- Setiap PDF bertanda "IJAZAH FIKTIF - UNTUK PENELITIAN", tanpa logo, tanda tangan, atau tata letak resmi UMKT.
- Nomor ijazah diseragamkan (hapus spasi tepi, huruf kapital) di skrip dan di halaman.
- Pindahkan ke iPhone lewat AirDrop ke aplikasi File; jangan dibuka lalu disimpan ulang.
