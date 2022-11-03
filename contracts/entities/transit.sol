// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../enums/transitStatus.sol";

struct Transit {
    string from;
    string to;
    uint startTime;
    uint endTime;
    TransitStatus status;
}
