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

### Formal Verification (Certora)

Basically, the reason why Certora won't catch the collision it that it assumes that a hash never collides with a constant. So there is a _probalbilistic assumption_ about hash collisions not happening, and memory integrity being preserved, which can seem counter-intuitive with _formal_ verification.

Interestingly, the possible collision is actually caught when the `OWNER_SLOT` is not a `constant`. It can be explained by the fact that the `OWNER_SLOT` will be initialized with a symbolic value, hence it understands that it can collide with any other storage slot value.

- [Results with the `constant` keyword (no violation)](https://prover.certora.com/output/196586/85560b5c4483446eaafe237c1d1a3554?anonymousKey=cc443b61e5ddd242338ea65b2a7aefb11c3ab7cb)
- [Results without the `constant` keyword (all violations are caught)](https://prover.certora.com/output/196586/e476d3647b664a21bf4ef09df179fa6e?anonymousKey=26d38528d09ef2b70ebda8cbefe92e10c1a0709d)

[Some documentation about hashings in Certora](https://docs.certora.com/en/latest/docs/prover/approx/hashing.html):

> The Certora Prover does not operate with an actual implementation of the Keccak hash function, since this would make most verification intractable and provide no practical benefits. Instead, the Certora Prover models the properties of the Keccak hash function that are crucial for the function of the smart contracts under verification while abstracting away from implementation details of the actual hash function.

> Furthermore, the initial storage slots are reserved, i.e., we make sure that no hash value ends up colliding with slots 0 to 10000.

_From explanations by [AlexNutz](https://github.com/alexandernutz) from the Certora team, possibly biased by my own understanding._

### Formal Verification (Halmos)

There are a few reasons why Halmos won't catch this:

1. The probability of a hash collision is _extremely_ low, so much that Halmos _assumes_ that it won't happen at all. It _is_ possible, eventually, but it's so unlikely that it would just provide countless counterexamples that are not really relevant.

2. When updating the storage, Halmos treats the location of this update as a separate location, so it doesn't even realize that it conflicts with the `OWNER_SLOT`. In the precise test, it _does_ know where the storage is updated—at the same location as the `OWNER_SLOT`—but it isn't designed to care about the possible—here realized—collision.

_From explanations by [karmacoma](https://twitter.com/0xkarmacoma) and [Daejun Park](https://twitter.com/daejunpark) from the Halmos team, possibly biased by my own understanding._

## How to not do this

There are a few things not to do when using arbitrary storage slots:

- don't use arbitrary storage slots if you don't really need it, or are not comfortable with hash collisions and storage integrity/slot calculation;
- obviously, if the slot calculation was not exposed here, it _should_ not be deducible from the contract—although this is not an excuse for not ensuring this can't happen;
- be careful when using a user-provided input as a key for a mapping, as it will be used for the slot calculation, so the user might be able to force a preimage—or just don't do it at all;

## You can't break cryptography with symbolic execution...

Yeah, formal verification won't actually _compute_ all possible hashes for a given parameter. Otherwise, it would not be really different that brute-forcing the hash. Take this example with Halmos, trying to break the `permit` function from OpenZeppelin's `ERC20Permit`:

```solidity
function check_generateSignature() external view {
    // Target values
    address target = address(1);
    address spender = address(2);
    uint256 value = 1 ether;
    uint256 deadline = 365 days;

    // Symbolic values
    uint8 v = uint8(svm.createUint(8, "v"));
    bytes32 r = svm.createBytes32("r");
    bytes32 s = svm.createBytes32("s");

    // Generate hash
    bytes32 hash =
        _hashTypedDataV4(keccak256(abi.encode(PERMIT_TYPEHASH, target, spender, value, nonce(target), deadline)));

    // Recover signer
    address signer = ECDSA.recover(hash, v, r, s);

    // Get counterexample where signer == target
    assert(signer != target);

    // Profit?
}
```

This seems like a good idea: generate symbolic values for `v`, `r` and `s`, take a given address to modify their approval for a specific sender, generate the hash, and recover the signer. At some point, for unique values of `v`, `r` and `s`, the signer _will_ be the target address. Halmos will provide you with the values for the counterexample, and you can use them to craft a transaction that impersonates any address!

Well, no. As we said, formal verification methods won't actually perform all this computation, one value after the other. Instead, they will "just" examine the possible combinations of values for `v`, `r` and `s`, and try to find a counterexample. Basically, it can tell that the assertion might indeed be violated _if_ such a combination of values exists. But it won't actually find it, nor will it even try to find it.

## Why should I use formal verification or fuzzing then?

Again, this is not a realistic exploit. It relies on multiple precise conditions, meticulously crafted for this challenge.

Fuzzing and formal verification are incredibly powerful methods. Especially in catching edge-cases, very specific-and-hard-to-notice-with-the-naked-eye bugs, e.g. precision-loss over multiple operations, or even just simple bugs. All that very efficiently.

You can't test, or visualize, all paths of a function, let alone a contract. Formal verification, especially with symbolic execution, can do that.

You can't keep track of _all_ the invariants of a contract, when auditing it by eye or basic tests. It sometimes rely on a 0.0000000001% difference in the state, that enables a terrible exploit. Stateful (invariant) fuzzing can catch that.

Developers _should_ write tests during the development process. Including fuzzing tests, and formal verification. Just a few small reasons (letting aside the necessity of testing in general):

1. It's a great way to catch edge-cases and unexpected behaviors early on, before replicating them on multiple components.

2. It provides a great overview of how the protocol _should_ work, what it _should_ hold true, and what it _shouldn't_ do. It's a great way to document the protocol, and to keep track of the invariants. Both for the developers, and for the auditors.

3. It allows for a more efficient audit, again by providing a great overview of the protocol, but also by:

   - catching the most obvious bugs early on;
   - providing a great overview of the protocol (yes, again);
   - offering a starting framework for the auditors to build upon;
   - freeing up time for the auditors to focus on the most important parts of the protocol, and more convoluted bugs... including the one we've been discussing here.

_Please_, write these tests. For the sake of your users, and for this whole industry as well.

---

Formal verification good. Fuzzing good. Comprehensive and thorough testing good.

Saving time and money at the expense of your users, risking their funds and geopardizing the whole stability of your protocol, when you claim that you're providing a safe and secure, let alone useful, protocol, although you _could_ put in the effort to test it properly and prevent such dramatic exploits from happening, bad.
