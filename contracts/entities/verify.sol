// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../enums/verifyStatus.sol";

struct Verify {
    uint uid;
    uint verifySubProduct;
    uint32 verifyStatus; // 0: rejected, 1: verified, 2: waiting
    uint verifyDate;
    address verifyAddress;
    uint verifyParentProduct;
}
