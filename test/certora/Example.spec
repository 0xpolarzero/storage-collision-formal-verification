/// @dev Verify:
/// certoraRun test/certora/Example_verified.conf

/* -------------------------------------------------------------------------- */
/*                                   METHODS                                  */
/* -------------------------------------------------------------------------- */

methods {
    function getOwner() external returns (address) envfree;
    
    function delegate(address target) external;
    function transferDelegation(address target) external;
}

/* -------------------------------------------------------------------------- */
/*                                    RULES                                   */
/* -------------------------------------------------------------------------- */

/// @dev The rule should be broken if:
/// - delegates[msg.sender] != address(0) // or whatever the current owner is
/// - transferDelegation is called with the address 0x000000004578616d706c654f776E6572536c6f74
/// @dev ✅ VERIFIED
rule changeOwnerGeneral(method f) {
    address owner = getOwner();

    env e;
    calldataarg args;
    f(e, args);

    assert getOwner() == owner;
}

/// @dev The rule should be broken if:
/// - transferDelegation is called with the address 0x000000004578616d706c654f776E6572536c6f74
/// @dev ✅ VERIFIED
rule changeOwnerGuidedSteps(method f) {
    address owner = getOwner();
    address target;
    env e;

    require target != owner;

    delegate(e, target);
    calldataarg args;
    f(e, args);

    assert getOwner() == owner;
}

/// @dev The rule should be broken.
rule changeOwnerPreciseSteps(method f) {
    address owner = getOwner();
    address attacker;
    address targetAddress = 0x000000004578616d706c654f776E6572536c6f74;

    require attacker != owner;

    env e;
    delegate(e, attacker);
    transferDelegation(e, targetAddress);

    assert getOwner() == owner;
}