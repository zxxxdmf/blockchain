#!/bin/zsh
set -e
cd "$(dirname "$0")/.."
anvil --silent --port 8547 & PID=$!
trap "kill $PID 2>/dev/null" EXIT
sleep 2
KUNCI=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ALAMAT=$(forge create src/pembanding/DocumentVerification.sol:DocumentVerification --rpc-url http://127.0.0.1:8547 --private-key $KUNCI --broadcast 2>/dev/null | awk '/Deployed to:/ {print $3}')
H=$(cast keccak "IJZ-FIKTIF-2026-001")
cast send $ALAMAT "storeDocument(bytes32,string)" $H "cid-fiktif" --rpc-url http://127.0.0.1:8547 --private-key $KUNCI >/dev/null
TERDAFTAR=$(cast call $ALAMAT "verifyDocument(bytes32)(bool)" $H --rpc-url http://127.0.0.1:8547)
LAIN=$(cast call $ALAMAT "verifyDocument(bytes32)(bool)" $(cast keccak "lain") --rpc-url http://127.0.0.1:8547)
echo "kontrak: $ALAMAT | hash terdaftar: $TERDAFTAR | hash lain: $LAIN"
[ "$TERDAFTAR" = "true" ] && [ "$LAIN" = "false" ] && echo "HASIL: LULUS" || { echo "HASIL: GAGAL"; exit 1; }
