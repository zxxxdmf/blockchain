#!/bin/zsh
set -e
cd "$(dirname "$0")/.."
RPC=http://127.0.0.1:8548
K0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
K1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
anvil --silent --port 8548 & PID=$!
bersihkan() {
  kill $PID 2>/dev/null || true
  if [ "$SIMPAN" != "1" ]; then
    rm -f jalur_qr/dokumen/*.pdf jalur_qr/dokumen/manifest.json hasil/mentah/qr_transaksi.csv \
          hasil/mentah/qr_penolakan.csv hasil/olahan/qr_kasus.csv
  fi
}
[ "$1" = "--simpan" ] && SIMPAN=1
trap bersihkan EXIT
sleep 2
PEMEGANG_A=$(cast wallet address --private-key $K1)

echo "1. deploy dan inisialisasi (skrip forge)"
KONTRAK=$(forge script script/DeployIjazah.s.sol --rpc-url $RPC --private-key $K0 --broadcast 2>/dev/null | awk '/IjazahSBT:/ {print $2}')
echo "   kontrak: $KONTRAK"
echo "2. penyiapan data jalur QR code"
.venv/bin/python -I jalur_qr/siapkan_data.py --rpc $RPC --kontrak $KONTRAK --kunci $K0 \
  --url-halaman https://contoh.github.io/eksperimen/halaman --pemegang-a $PEMEGANG_A
echo "3. tujuh kasus Tabel 2.7 melalui cast"
.venv/bin/python -I jalur_qr/cek_kasus.py --rpc $RPC
echo "4. uji penolakan transfer dan penerbitan tanpa peran"
.venv/bin/python -I jalur_qr/uji_penolakan.py --rpc $RPC --kunci-pemegang $K1
echo "5. logika halaman verifikasi (verifikasi.js)"
node halaman/uji_logika.js $RPC
