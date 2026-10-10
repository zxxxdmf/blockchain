#!/bin/zsh
# Pemeriksa kelengkapan lingkungan eksperimen terhadap Tabel 2.3 dan Tabel 2.4 naskah.
# Tidak pernah mencetak isi .env atau kunci. Pemakaian: ./cek_lingkungan.sh
cd "$(dirname "$0")"
OK=0; KURANG=0
ok()     { print -P "  %F{green}OK%f      $1"; OK=$((OK+1)); }
kurang() { print -P "  %F{red}KURANG%f  $1"; KURANG=$((KURANG+1)); }
manual() { print -P "  %F{yellow}MANUAL%f  $1"; }
cek()    { [ "$2" = "$3" ] && ok "$1: $2" || kurang "$1: terpasang '${2:-tidak ada}', naskah '$3'"; }

echo "Perangkat keras (Tabel 2.3)"
[ "$(sysctl -n machdep.cpu.brand_string)" = "Apple M4" ] && [ "$(sysctl -n hw.memsize)" = "17179869184" ] \
  && ok "MacBook Air M4, RAM 16 GB" || kurang "laptop tidak sesuai Tabel 2.3"
manual "ponsel Apple iPhone 15 dengan Safari iOS (baris 2 Tabel 2.3, baris 8 Tabel 2.4)"

echo "Perangkat lunak (Tabel 2.4)"
cek "1  macOS" "$(sw_vers -productVersion)" "26.5.1"
for a in forge anvil cast; do cek "2  Foundry ($a)" "$($a --version 2>/dev/null | head -1 | awk '{print $3}')" "1.8.3"; done
[ -x "$HOME/Library/Application Support/svm/0.8.37/solc-0.8.37" ] && ok "3  Solidity compiler: 0.8.37" || kurang "3  solc 0.8.37 belum ada (jalankan forge build)"
cek "4  OpenZeppelin Contracts" "$(git -C lib/openzeppelin-contracts describe --tags 2>/dev/null)" "v5.7.0"
cek "5  forge-std" "$(git -C lib/forge-std describe --tags 2>/dev/null)" "v1.17.0"
cek "6  Python" "$(.venv/bin/python -c 'import sys;print(sys.version.split()[0])' 2>/dev/null)" "3.14.7"
for p in qrcode:8.2 pillow:12.3.0 reportlab:5.0.1; do
  cek "6  pustaka ${p%%:*}" "$(.venv/bin/python -c "from importlib.metadata import version;print(version('${p%%:*}'))" 2>/dev/null)" "${p#*:}"
done
cek "7  ethers.js (Node)" "$(node -e "console.log(require('ethers').version)" 2>/dev/null)" "6.17.0"
[ -s halaman/vendor/ethers-6.17.0.umd.min.js ] && ok "7  ethers.js lokal untuk halaman verifikasi" || kurang "7  halaman/vendor/ethers-6.17.0.umd.min.js tidak ada"
cek "9  Visual Studio Code" "$(code --version 2>/dev/null | head -1)" "1.140.0"
cek "10 Git" "$(git --version | awk '{print $3}')" "2.52.0"

echo "Layanan daring (Tabel 2.4) dan bahan ETH Sepolia (Tabel 2.5)"
[ -f .env ] && source ./.env
if [ -n "$SEPOLIA_RPC_URL" ]; then
  [ "$(cast chain-id --rpc-url "$SEPOLIA_RPC_URL" 2>/dev/null)" = "11155111" ] && ok "11-12 Sepolia lewat Infura terhubung" \
    || kurang "11-12 SEPOLIA_RPC_URL terisi tetapi tidak terhubung ke Sepolia"
else kurang "11-12 SEPOLIA_RPC_URL (Infura) belum diisi di .env"; fi
[ -n "$ETHERSCAN_API_KEY" ] && ok "13 ETHERSCAN_API_KEY terisi" || kurang "13 ETHERSCAN_API_KEY belum diisi di .env"
if cast wallet list 2>/dev/null | grep -q "^${AKUN_DEPLOY:-penerbit}"; then
  ok "akun keystore '${AKUN_DEPLOY:-penerbit}' ada"
  if [ -n "$SEPOLIA_RPC_URL" ]; then
    if [ -n "$ALAMAT_DEPLOY" ]; then
      SALDO=$(cast balance "$ALAMAT_DEPLOY" --ether --rpc-url "$SEPOLIA_RPC_URL" 2>/dev/null)
      [ -n "$SALDO" ] && [ "$SALDO" != "0.000000000000000000" ] && ok "saldo ETH Sepolia: $SALDO" || kurang "saldo ETH Sepolia kosong"
    else kurang "ALAMAT_DEPLOY (alamat publik akun) belum diisi di .env untuk cek saldo"; fi
  fi
else kurang "akun keystore '${AKUN_DEPLOY:-penerbit}' belum dibuat (cast wallet import ... --interactive)"; fi
git remote get-url origin >/dev/null 2>&1 && ok "14 repositori GitHub tersambung: $(git remote get-url origin)" \
  || kurang "14 repositori GitHub (untuk publikasi dan GitHub Pages) belum disambungkan"

echo "Uji alat (bukan bagian penelitian)"
FOUNDRY_PROFILE=ujialat forge test --match-contract RantaiTest >/dev/null 2>&1 && ok "solc + OpenZeppelin + forge-std + kontrak pembanding" || kurang "uji RantaiTest gagal"
.venv/bin/python -I uji_alat/cek_rantai_qr.py 2>/dev/null | grep -q "HASIL: LULUS" && ok "QR code + PDF invariant + keccak cast = ethers.js" || kurang "uji cek_rantai_qr.py gagal"
./uji_alat/cek_anvil.sh 2>/dev/null | grep -q "HASIL: LULUS" && ok "deploy Anvil + panggilan cast" || kurang "uji cek_anvil.sh gagal"

echo "Kode penelitian"
forge test --match-path 'test/acuan/unit/*' 2>/dev/null | grep -q "33 passed; 0 failed" && ok "kontrak acuan lulus 33 unit test berskenario tetap" || kurang "unit test kontrak acuan tidak lulus semua"
[ "$(ls -d varian/terencana/C* 2>/dev/null | wc -l | tr -d ' ')" = "9" ] && [ "$(ls -d varian/sistematis/S* 2>/dev/null | wc -l | tr -d ' ')" = "48" ] \
  && ok "varian: 9 terencana, 48 sistematis" || kurang "varian belum dibangkitkan (varian/buat_varian.py)"
./script/cek_aturan_anvil.sh 2>/dev/null | grep -q "HASIL: LULUS" && ok "Tahap 2: aturan Tabel 2.1 melalui cast di Anvil (31 pemeriksaan)" || kurang "pemeriksaan aturan Tahap 2 di Anvil gagal"
./jalur_qr/gladi_anvil.sh 2>/dev/null | grep -q "13 dari 13 pemeriksaan logika halaman sesuai" && ok "gladi Tahap 7 di Anvil (cast, penolakan, halaman)" || kurang "gladi Tahap 7 gagal"
grep -q "0x0000000000000000000000000000000000000000" halaman/config.js && kurang "halaman/config.js belum diisi alamat kontrak Sepolia dan RPC" || ok "halaman/config.js terisi"

echo; echo "Ringkasan: $OK OK, $KURANG KURANG (butir MANUAL diperiksa sendiri)"
