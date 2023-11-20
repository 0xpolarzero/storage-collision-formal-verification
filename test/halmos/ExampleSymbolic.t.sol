// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import {Example} from "src/Example.sol";

contract ExampleSymbolic is SymTest, Test {
    Example example;

    address constant TARGET_ADDRESS = 0x000000004578616d706c654f776E6572536c6f74;

    function setUp() external {
        example = new Example();
    }

    /// @dev This should indeed pass—the `delegate` function is not enough to overwrite the owner
    function check_delegate_ownerNeverChanges() external {
        address target = svm.createAddress("target");
        address ownerBefore = example.getOwner();

        example.delegate(target);

        assertEq(example.getOwner(), ownerBefore, "owner not changed");
    }

    /// @dev All values are initialized at 0, so:
    /// - the address at `OWNER_SLOT` is 0x0
    /// - the address at `delegates[msg.sender]` is 0x0
    /// => obviously the owner doesn't change.
    /// However, should the contract state not be initialized with symbolic values?
    /// @dev In this case, why doesn't it catch the disrepancy it would cause if:
    /// - owner != delegates[msg.sender]
    /// - `transferDelegation` is called with the exact single address that causes a collision
    function check_transferDelegation_ownerAlwaysTheSame() external {
        address target = svm.createAddress("target");
        address ownerBefore = example.getOwner();

        example.transferDelegation(target);

        assertEq(example.getOwner(), ownerBefore, "owner not changed");
    }

    /// @dev This one should definitely pass, right?
    /// The only condition is that target = TARGET_ADDRESS
    function check_GUIDED_ownerAlwaysTheSame() external {
        address target = svm.createAddress("target");
        address ownerBefore = example.getOwner();

        vm.assume(address(this) != ownerBefore);

        example.delegate(address(this));
        example.transferDelegation(target);

        assertEq(example.getOwner(), ownerBefore, "owner not changed");
    }

    /// @dev Even this passes, although it does almost seem like a unit test. Why?
    function check_DEFINED_ownerAlwaysTheSame() external {
        address ownerBefore = example.getOwner();

        vm.assume(address(this) != ownerBefore);

        example.delegate(address(this));
        example.transferDelegation(TARGET_ADDRESS);

        assertEq(example.getOwner(), ownerBefore, "owner not changed");
    }
}
