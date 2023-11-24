// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {console} from "forge-std/console.sol";

contract Example {
    using StorageSlot for bytes32;

    error CannotTransferDelegation();

    // keccak256(abi.encodePacked(COUNTER, NAME, VERSION))
    // (uint128(0), "ExampleOwnerSlot", uint256(1))
    bytes32 constant OWNER_SLOT = 0x13bb85518f574144ff9b162bdf31313f2d495714b5b456e7ac192a698d8aa3c1;
    // @audit Or remove the constant keyword to see Certora actually catch the collision
    // bytes32 OWNER_SLOT = 0x13bb85518f574144ff9b162bdf31313f2d495714b5b456e7ac192a698d8aa3c1;

    mapping(address => uint256) public balances; // storage slot 0
    mapping(address => address) public delegates; // storage slot 1

    constructor() {
        _setOwner(address(0));
    }

    function delegate(address to) external {
        delegates[msg.sender] = to;
    }

    function transferDelegation(address to) external {
        if (delegates[to] != address(0) && delegates[msg.sender] != delegates[to]) {
            revert CannotTransferDelegation();
        }

        delegates[to] = delegates[msg.sender];
    }

    function getOwner() external view returns (address) {
        return OWNER_SLOT.getAddressSlot().value;
    }

    function _setOwner(address owner) internal {
        OWNER_SLOT.getAddressSlot().value = owner;
    }
}
