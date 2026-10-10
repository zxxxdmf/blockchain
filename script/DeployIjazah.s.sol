// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Script, console2} from "forge-std/Script.sol";
import {IjazahSBT} from "src/IjazahSBT.sol";

/// @title Deploy dan inisialisasi kontrak acuan dalam satu skrip forge (Tahap 7)
/// @notice Akun pengirim menjadi admin pertama sekaligus penerbit. Pemakaian (Sepolia, dengan verifikasi Etherscan):
///   source .env
///   forge script script/DeployIjazah.s.sol --rpc-url sepolia --account $AKUN_DEPLOY --broadcast --verify
/// Untuk uji lokal: anvil, lalu --rpc-url http://127.0.0.1:8545 --private-key <kunci anvil> --broadcast
contract DeployIjazah is Script {
    function run() external returns (IjazahSBT ijazah) {
        vm.startBroadcast();
        (, address akun,) = vm.readCallers();
        ijazah = new IjazahSBT();
        ijazah.inisialisasi(akun);
        ijazah.tetapkanPenerbit(akun);
        vm.stopBroadcast();
        console2.log("IjazahSBT:", address(ijazah));
        console2.log("admin dan penerbit:", akun);
    }
}
