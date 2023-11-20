// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {Handler} from "./Handler.t.sol";

import {Example} from "src/Example.sol";

contract InvariantsStateful is StdInvariant, Test {
    Example example;
    Handler handler;
    address owner;

    function setUp() external {
        example = new Example();
        owner = example.getOwner();

        handler = new Handler(example);
        targetContract(address(handler));
    }

    function invariant_stateful_ownerNeverChanges() external view {
        assert(example.getOwner() == owner);
    }
}
