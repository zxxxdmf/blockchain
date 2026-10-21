#!/bin/zsh
set -e
cd "$(dirname "$0")/.."
RPC=http://127.0.0.1:8549
K0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
anvil --silent --port 8549 & PID=$!
trap "kill $PID 2>/dev/null; rm -rf broadcast/DeployIjazah.s.sol/31337" EXIT
sleep 2
KONTRAK=$(forge script script/DeployIjazah.s.sol --rpc-url $RPC --private-key $K0 --broadcast 2>/dev/null | awk '/IjazahSBT:/ {print $2}')
echo "kontrak acuan di Anvil: $KONTRAK"
.venv/bin/python -I script/cek_aturan_anvil.py $RPC $KONTRAK
