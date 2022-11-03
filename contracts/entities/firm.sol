// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../enums/roles.sol";

struct Firm {
    string firmName;
    string firmLocation;
    Roles role;
    address firmAddress;
}
