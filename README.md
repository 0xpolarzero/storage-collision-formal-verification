An example of how some automated testing tools will fail to discover a very precise exploit in a contract. Namely, fuzzing, formal verification (Certora) and symbolic execution (Halmos).

_This is not a realistic exploit. Here, it relies on the fact that the calculation of the storage slot for the owner is publicly available, and incidentally involves the same storage value as the one used for the delegation... which can be changed with entirely arbitrary values._

## Overview

The issue is quite simple, yet very unique.

Basically, it occurs in a two-step process:

1. A user calls `delegate` with any address (different than the current address at the `OWNER_SLOT`);
2. The user calls `transferDelegation` with a unique address, that when hashed will produce a storage slot that collides with the `OWNER_SLOT`.
   => which will write the address passed in the first step on the `OWNER_SLOT`, effectively changing the owner of the contract.

## Running the exploit

See [ExampleUnit.t.sol](./test/unit/ExampleUnit.t.sol) for the exploit code. You will need to have [Foundry installed](https://book.getfoundry.sh/getting-started/installation).

`forge test --mt test_ownerAlwaysTheSame`

## Why is this not caught?

### Fuzzing

With [stateless fuzzing](./test/fuzzing/stateless/), it's just impossible to catch this. The exploit requires a prior call to `delegate`; otherwise, the call to `transferDelegation`, even with the precise exploit address, will just override the `OWNER_SLOT` with the address 0 (current delegates). Which is precisely what the owner is already.

With [stateful fuzzing](./test/fuzzing/stateful/), it becomes a _possibility_. Well, whenever an address calling `transferDelegation` has already called `delegate`, with any address, in the same run. However, it would need to pass the exact unique address that would collide with the `OWNER_SLOT`. Not impossible, but very unlikely.

### Formal Verification

Certora/Halmos: no idea; waiting for answers from the teams.
