// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Test} from "forge-std/Test.sol";

contract Tangga {
    uint256 public langkah;

    function naik(uint256 x) external {
        if (x % 60 == langkah * 20) langkah++;
    }
}

contract KeterulanganTest is Test {
    Tangga t;

    function setUp() public {
        t = new Tangga();
        targetContract(address(t));
    }

    function invariant_belumSampaiAtas() public view {
        assertLt(t.langkah(), 3);
    }
}
