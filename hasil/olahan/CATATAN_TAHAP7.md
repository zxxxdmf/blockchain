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
