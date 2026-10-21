// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Script, console2} from "forge-std/Script.sol";
import {IjazahSBT} from "src/IjazahSBT.sol";

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
