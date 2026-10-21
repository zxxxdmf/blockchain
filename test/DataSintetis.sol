// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library DataSintetis {
    uint256 internal constant JUMLAH = 10;

    function nomor(uint256 k) internal pure returns (string memory) {
        uint256 n = k % JUMLAH + 1;
        return string.concat("IJZ-FIKTIF-2026-", n < 10 ? "00" : "0", Strings.toString(n));
    }

    function teksDokumen(uint256 k) internal pure returns (string memory) {
        return string.concat("Dokumen ijazah ", nomor(k));
    }

    function hashNomor(uint256 k) internal pure returns (bytes32) {
        return keccak256(bytes(nomor(k)));
    }

    function hashDokumen(uint256 k) internal pure returns (bytes32) {
        return keccak256(bytes(teksDokumen(k)));
    }

    function hashDokumenPengganti(uint256 k, uint256 urut) internal pure returns (bytes32) {
        return keccak256(bytes(string.concat(teksDokumen(k), " #", Strings.toString(urut))));
    }
}
