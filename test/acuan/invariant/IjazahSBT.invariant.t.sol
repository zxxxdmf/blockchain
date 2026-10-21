// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";
import {IjazahSBT} from "src/IjazahSBT.sol";
import {DataSintetis as D} from "test/DataSintetis.sol";
import {HandlerIjazah} from "test/acuan/invariant/HandlerIjazah.sol";

contract IjazahSBTInvariantTest is Test {
    IjazahSBT ijazah;
    HandlerIjazah handler;
    address[5] aktor;

    function setUp() public {
        aktor = [
            makeAddr("admin"), makeAddr("penerbit"), makeAddr("pemegangA"), makeAddr("pemegangB"), makeAddr("penyerang")
        ];
        ijazah = new IjazahSBT();
        ijazah.inisialisasi(aktor[0]);
        vm.prank(aktor[0]);
        ijazah.tetapkanPenerbit(aktor[1]);

        handler = new HandlerIjazah(ijazah, aktor);
        targetContract(address(handler));
        bytes4[] memory s = new bytes4[](9);
        s[0] = HandlerIjazah.terbitkan.selector;
        s[1] = HandlerIjazah.terbitkanUlang.selector;
        s[2] = HandlerIjazah.cabut.selector;
        s[3] = HandlerIjazah.transfer.selector;
        s[4] = HandlerIjazah.gantiAdmin.selector;
        s[5] = HandlerIjazah.tetapkanPenerbit.selector;
        s[6] = HandlerIjazah.hapusPenerbit.selector;
        s[7] = HandlerIjazah.inisialisasiUlang.selector;
        s[8] = HandlerIjazah.verifikasi.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: s}));
    }

    function _jumlahToken() internal view returns (uint256) {
        return ijazah.idBerikutnya() - 1;
    }

    function invariant_I1() public view {
        assertEq(_jumlahToken(), handler.jumlahTerbitSah(), "I1: ada token yang diterbitkan selain oleh penerbit");
    }

    function invariant_I2() public view {
        for (uint256 id = 1; id <= _jumlahToken(); ++id) {
            address awal = handler.pemilikAwal(id);
            if (awal == address(0)) continue;
            assertEq(ijazah.ownerOf(id), awal, "I2a: pemilik token berubah setelah diterbitkan");
            assertTrue(ijazah.locked(id), "I2b: locked tidak bernilai benar");
        }
    }

    function invariant_I3() public view {
        for (uint256 id = 1; id <= _jumlahToken(); ++id) {
            (,, bool dicabut) = ijazah.dataToken(id);
            if (dicabut) assertTrue(handler.dicabutSah(id), "I3: token dicabut oleh selain penerbit");
        }
    }

    function invariant_I4() public view {
        for (uint256 id = 1; id <= _jumlahToken(); ++id) {
            (bytes32 hn,, bool dicabut) = ijazah.dataToken(id);
            if (handler.pernahDicabut(id)) assertTrue(dicabut, "I4a: token yang dicabut aktif kembali");
            if (!dicabut && handler.dataPernahDicabut(hn)) {
                assertTrue(
                    handler.pengganti(id) && handler.terbitSah(id),
                    "I4b: data yang dicabut aktif lagi bukan melalui token pengganti dari penerbit"
                );
            }
        }
    }

    function invariant_I5() public view {
        uint256 n = _jumlahToken();
        for (uint256 k; k < D.JUMLAH; ++k) {
            bytes32 hk = D.hashNomor(k);
            uint256 aktif;
            for (uint256 id = 1; id <= n; ++id) {
                (bytes32 hn,, bool dicabut) = ijazah.dataToken(id);
                if (hn == hk && !dicabut) ++aktif;
            }
            assertLe(aktif, 1, "I5: satu data ijazah memiliki lebih dari satu token aktif");
        }
    }

    function invariant_I6() public view {
        bytes32 adm = ijazah.DEFAULT_ADMIN_ROLE();
        bytes32 pen = ijazah.PENERBIT();
        for (uint256 i; i < 5; ++i) {
            address x = handler.aktorKe(i);
            assertEq(
                ijazah.hasRole(adm, x), x == handler.bayanganAdmin(), "I6a: daftar admin berubah tidak melalui admin"
            );
            assertEq(
                ijazah.hasRole(pen, x), handler.bayanganPenerbit(x), "I6b: daftar penerbit berubah tidak melalui admin"
            );
        }
        assertEq(handler.inisialisasiUlangBerhasil(), 0, "I6c: inisialisasi dapat dipanggil lebih dari satu kali");
    }

    function invariant_I7() public view {
        assertEq(handler.salahVerifikasi(0), 0, "I7a: seharusnya tidak terdaftar");
        assertEq(handler.salahVerifikasi(1), 0, "I7b: seharusnya tidak cocok");
        assertEq(handler.salahVerifikasi(2), 0, "I7c: seharusnya dicabut");
        assertEq(handler.salahVerifikasi(3), 0, "I7d: seharusnya aktif");
    }
}
