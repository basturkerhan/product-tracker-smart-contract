// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Helper {
    // function getUniqueId(string calldata _text) public view returns (bytes32) {
    //     return keccak256(abi.encode(_text, block.timestamp));
    // }

    function getUniqueId(uint _number) public view returns (uint) {
        return block.timestamp+_number;
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
