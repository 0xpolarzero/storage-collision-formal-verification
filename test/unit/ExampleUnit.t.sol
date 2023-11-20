// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Example} from "src/Example.sol";

contract ExampleUnit is Test {
    /// @dev Basically the exploit process is the following:
    /// 1. The attacker calls `delegate` with their own address;
    /// 2. The attacker calls `transferDelegation` with a carefully crafted address
    /// (which will return the same storage slot as the `OWNER_SLOT`)
    function test_ownerAlwaysTheSame() public {
        Example example = new Example();
        address attacker = makeAddr("attacker");

        // * OWNER_SLOT:
        // keccak256(abi.encodePacked(uint128(0), "ExampleOwnerSlot", uint256(1)))
        // * delegates (at storage slot value 1) storage location for address a:
        // keccak256(abi.encode(a, uint256(1)))
        // * Basically we need to find:
        // a == abi.encodePacked(uint128(0), "ExampleOwnerSlot")
        // which can happen because the right side is exactly 32 bytes

        address ownerBefore = example.getOwner();

        // Encode the target bytes32
        bytes32 target = bytes32(abi.encodePacked(uint128(0), "ExampleOwnerSlot"));
        // This is what we'll pass to overwrite the value at `OWNER_SLOT`
        // When turned into 32 bytes (with `abi.encode`), it will be left-padded with 0s
        // ... which is perfectly fine, since our target starts with `uint128(0)`; plenty of room for us
        address targetAddress = address(uint160(uint256(target))); // 0x000000004578616d706c654f776E6572536c6f74

        vm.startPrank(attacker);
        // Delegate attacker => attacker
        example.delegate(attacker);
        // Transfer the delegation to the crafted address
        // which is a key in the mapping, so it will be used to calculate the hash of the storage slot
        // ... and return exactly the same as the `OWNER_SLOT`
        example.transferDelegation(targetAddress);
        vm.stopPrank();

        address ownerAfter = example.getOwner();
        assertEq(ownerBefore, ownerAfter, "owner has changed");
    }
}
