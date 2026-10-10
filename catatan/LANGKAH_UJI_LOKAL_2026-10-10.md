# Langkah Uji Coba Lokal Penuh (2026-10-10)

Uji coba seluruh Tahap 5 di lingkungan lokal setelah penulis menyetujui semua golongan varian sistematis.
Tidak ada deploy ke Sepolia. Hasilnya diarsipkan sebagai hasil pra-penguncian, bukan hasil Tahap 5.

Keadaan saat panduan ini dibuat (diperiksa 2026-10-10):
- `./cek_lingkungan.sh`: 23 OK, 5 KURANG. Kelima butir KURANG semuanya untuk Sepolia dan GitHub.
- `varian/sistematis/daftar.csv` identik dengan `usulan_golongan.csv` (48 varian, tanpa perbedaan).
- `hasil/olahan/` dan `hasil/mentah/` masih kosong. Repositori Git belum punya commit.

## Sebelum mulai

- **Ini uji coba, bukan hasil Tahap 5.** Commit penguncian baru dilakukan setelah proposal disetujui. Hasil uji
  ini diarsipkan ke `hasil/pra_penguncian/2026-10-10/`, seperti hasil 2026-10-09.
- **Persetujuan golongan di-commit sebelum eksekusi.** Naskah menyatakan golongan ditetapkan sebelum eksekusi dan
  tidak diubah sesudahnya. Commit ini menjadi bukti waktunya.
- **Jangan mengubah invariant, handler, atau unit test karena hasil varian.** Sebagian varian memang diperkirakan
  lolos menurut alasan di usulan golongan, misalnya varian alamat nol dan hash kosong yang tidak terjangkau handler.
  Itu temuan, bukan kesalahan. Menambah invariant setelah melihat hasil membuat klaim naskah tidak jujur.
- Jangan menjalankan `forge fmt` atau menyunting `src/`, `test/`, dan `varian/` selama uji coba.

Colokkan charger dan jangan menutup laptop. Perintah yang lama memakai awalan `caffeinate -i` agar Mac tidak tidur.
Semua perintah dijalankan dari folder eksperimen:

```
cd /Users/fzl/proposalnew/eksperimen
```

## Langkah eksekusi

### Langkah 1. Periksa lingkungan (sekitar 30 detik)

```
./cek_lingkungan.sh
```

Hasil yang diharapkan: 23 OK dan 5 KURANG. Kelima butir KURANG harus persis butir berikut:
- SEPOLIA_RPC_URL
- ETHERSCAN_API_KEY
- keystore penerbit
- repositori GitHub
- config.js halaman

Bila ada butir lain yang KURANG, berhenti dan simpan keluarannya. Pemeriksa ini sudah menjalankan unit test,
pemeriksaan aturan di Anvil, dan gladi jalur QR code, jadi Tahap 2 tidak perlu dijalankan terpisah.

### Langkah 2. Catat persetujuan golongan, lalu commit

Pastikan daftar yang dipakai skrip sama dengan usulan. Keluaran yang diharapkan: `beda: []`.

```
.venv/bin/python -I -c "
import csv
u={r['id']:(r['relevan'],r['golongan']) for r in csv.DictReader(open('varian/sistematis/usulan_golongan.csv'))}
d={r['id']:(r['relevan'],r['golongan']) for r in csv.DictReader(open('varian/sistematis/daftar.csv'))}
print('jumlah:',len(u),len(d),'beda:',[k for k in u if u[k]!=d[k]])"
```

Tambahkan catatan persetujuan ke log perubahan:

```
cat >> catatan/LOG_PERUBAHAN.md <<'EOF'
- 2026-10-10: penulis meninjau dan menyetujui seluruh golongan di varian/sistematis/usulan_golongan.csv (48 varian)
  tanpa perubahan; daftar.csv identik dengan usulan. Golongan ditetapkan sebelum uji coba lokal penuh dan tidak
  diubah sesudahnya. Commit penguncian kode pengujian tetap dilakukan setelah proposal disetujui.
EOF
```

Buat commit pertama dan catat kodenya:

```
git add -A
git status --short | head -30
git commit -m "Persetujuan golongan varian sistematis sebelum uji coba lokal"
git tag golongan-disetujui-2026-10-10
git log --oneline -1
```

Sebelum commit, periksa daftar dari `git status`. Folder `.venv`, `node_modules`, `cache`, `otomasi/_kerja`,
dan berkas `.env` tidak boleh ikut.

### Langkah 3. Kontrol kontrak acuan (70 kampanye, sekitar 5 menit)

```
caffeinate -i .venv/bin/python -I otomasi/jalankan.py acuan
.venv/bin/python -I otomasi/ringkas.py
column -s, -t hasil/olahan/kontrol_acuan.csv
```

Setiap invariant I1 sampai I7 harus lulus pada 10 dari 10 seed. Pelanggaran di sini adalah pelanggaran palsu.
Bila ada, berhenti, karena langkah berikutnya tidak bermakna sebelum kontrol bersih.

### Langkah 4. Varian terencana C1 sampai C9 (90 kampanye, sekitar 5 sampai 10 menit)

```
caffeinate -i .venv/bin/python -I otomasi/jalankan.py terencana
```

Pada uji coba 2026-10-09, kesembilan varian terdeteksi oleh invariant sasarannya pada seed 1 sampai 3.
Hasil per varian dibaca pada Langkah 8.

### Langkah 5. Varian sistematis (3.360 kampanye, sekitar 4 sampai 7 jam)

Jumlahnya 48 varian x 7 invariant x 10 seed.

```
caffeinate -i .venv/bin/python -I otomasi/jalankan.py sistematis
```

Pantau kemajuan dari terminal lain (angkanya naik sampai 3.360):

```
grep -c '^sistematis,' hasil/olahan/kampanye.csv
```

Bila proses terputus, jalankan ulang perintah yang sama. Skrip melewati kampanye yang sudah tercatat. Jangan
memakai opsi `--ulang`, karena opsi itu membuat baris ganda di berkas hasil. S01B dan S02B akan tercatat sebagai
gagal disiapkan, sesuai golongannya.

### Langkah 6. Kontrak pembanding (50 kampanye, sekitar 10 sampai 15 menit)

```
caffeinate -i .venv/bin/python -I otomasi/jalankan.py pembanding
```

Pada uji coba sebelumnya, semua kampanye lulus. Bila ada yang terdeteksi, jangan langsung menyebutnya kesalahan
kontrak Bimantoro et al. (2026). Catat seed dan invariant-nya. Urutannya harus diuji ulang langsung ke kontrak
tanpa handler (`test/pembanding/UlangPelanggaran.t.sol`), sesuai prosedur naskah.

### Langkah 7. Unit test pada semua varian (58 target, sekitar 5 menit)

```
caffeinate -i .venv/bin/python -I otomasi/jalankan.py unit
```

Targetnya kontrak acuan dan 57 varian. Pada uji coba sebelumnya, unit test tidak mendeteksi C8 dan S23H.
Jangan menambah kasus uji karena hasil itu.

### Langkah 8. Ringkas dan baca hasil

```
.venv/bin/python -I otomasi/ringkas.py
cut -d, -f1,2,5,7,8,18,20 hasil/olahan/ringkasan_varian.csv | column -s, -t
column -s, -t hasil/olahan/perbandingan_golongan.csv
column -s, -t hasil/olahan/varian_terpisah.csv | cut -c1-120
```

Yang diperiksa:
- **kontrol_acuan.csv**: tetap 10 dari 10 untuk ketujuh invariant.
- **ringkasan_varian.csv**: kolom `seed_mendeteksi` menunjukkan berapa dari 10 seed yang menangkap setiap varian.
  Bila `shrink_cocok_golongan` berisi "tidak", laporkan apa adanya dan jangan mengubah golongan.
- **varian_terpisah.csv**: tujuh varian, yaitu lima tanpa pemicu dan dua gagal disiapkan.
- **perbandingan_golongan.csv**: hitungan kedua cara, hanya stateful fuzzing, hanya unit test, dan tidak
  terdeteksi, per golongan dan per kriteria (10 seed dan minimal 1 seed).
- **pelanggaran.csv**: urutan transaksi pemicu setelah shrinking, bahan sequence diagram.

### Langkah 9. Gladi jalur QR code di Anvil (opsional, sekitar 15 detik)

```
./jalur_qr/gladi_anvil.sh
```

Keluaran yang diharapkan diakhiri "13 dari 13 pemeriksaan logika halaman sesuai". PDF dan alamat kontrak dari
gladi ini dihapus otomatis. Pengujian dari iPhone tidak dapat dilakukan di sini karena Anvil hanya dapat diakses
dari laptop; pengujian itu menunggu tahap Sepolia.

## Setelah selesai

### Langkah 10. Arsipkan hasil uji coba (wajib)

Skrip melewati semua kampanye yang sudah tercatat di `hasil/olahan/kampanye.csv`. Bila hasil uji coba tidak
dipindahkan, eksekusi resmi setelah penguncian akan melewati semuanya dan tidak menjalankan apa pun.

```
D=hasil/pra_penguncian/2026-10-10
mkdir -p $D/mentah
mv hasil/olahan/*.csv $D/
mv hasil/mentah/* $D/mentah/
echo "$D/mentah/" >> .gitignore
du -sh $D/mentah
```

Keluaran mentah diperkirakan sekitar 2 GB (sekitar 650 KB per kampanye karena jejak lengkap forge), jadi folder
mentah tidak dimasukkan ke Git. Ruang kosong laptop saat panduan dibuat sekitar 47 GB.

Buat README singkat di folder arsip, lalu commit:

```
cat > $D/README.md <<'EOF'
# Uji coba lokal penuh (2026-10-10)

Uji coba seluruh Tahap 5 di lingkungan lokal setelah golongan disetujui (tag golongan-disetujui-2026-10-10),
sebelum commit penguncian. Bukan hasil Tahap 5. Tidak ada deploy ke Sepolia.
Isi: kampanye.csv, unit.csv, dan tabel ringkas.py. Keluaran forge mentah ada di mentah/ (tidak di-commit, sekitar 2 GB).
EOF
git add -A
git commit -m "Arsip uji coba lokal penuh 2026-10-10 (pra-penguncian)"
```

## Catatan untuk eksekusi resmi nanti

Keluaran mentah sekitar 2 GB tidak layak masuk repositori GitHub yang akan dipublikasikan. Perlu diputuskan
apakah keluaran mentah disimpan terpisah (misalnya sebagai berkas arsip di rilis GitHub) atau hanya tabel olahan
yang dipublikasikan.
