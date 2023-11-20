// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {Example} from "src/Example.sol";

contract InvariantsStateless is StdInvariant, Test {
    Example example;
    address owner;

    function setUp() external {
        example = new Example();
        owner = example.getOwner();
    }

    function invariant_stateless_ownerNeverChanges() external view {
        assert(example.getOwner() == owner);
    }
}
