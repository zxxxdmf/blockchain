// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";

contract Penghitung {
    uint256 public n;

    function tambah() external {
        ++n;
    }
}

contract ResetRunTest is Test {
    Penghitung p;

    function setUp() public {
        p = new Penghitung();
        targetContract(address(p));
    }

    function invariant_tidakMelewatiDepth() public view {
        assertLe(p.n(), 100, "keadaan terbawa dari run sebelumnya");
    }

    function afterInvariant() public view {
        assertEq(p.n(), 100, "akhir run: penghitung harus tepat depth");
    }
}
