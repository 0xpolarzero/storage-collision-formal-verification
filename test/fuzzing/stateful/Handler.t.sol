// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Example} from "src/Example.sol";

contract Handler is Test {
    Example example;
    address attacker;

    // The address to pass to `transferDelegation` to overwrite the owner
    address constant TARGET_ADDRESS = 0x000000004578616d706c654f776E6572536c6f74;

    constructor(Example _example) {
        example = _example;
    }

    function delegate(address _target) external {
        example.delegate(_target);
    }

    function transferDelegation(address _target) external {
        example.transferDelegation(_target);
    }

    /// @dev Uncomment this to see the invariant break instantly
    // function BREAK_transferDelegation() external {
    //     example.transferDelegation(TARGET_ADDRESS);
    // }
}
