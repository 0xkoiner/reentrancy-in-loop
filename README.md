# Reentrancy in Loop: A Deep Dive into a Solidity Vulnerability

### Overview
During a public audit, I identified a potential vector for a reentrancy attack vulnerability in a Solidity smart contract. As a diligent security researcher, I traced the attack, developed a Proof of Concept (PoC), and tested it extensively. However, despite my theoretical analysis suggesting a successful exploit, my tests consistently failed with the error:

```bash
error ← [OutOfFunds] EvmError: OutOfFunds
```

This README documents my journey down the rabbit hole, the debugging process, and the ultimate realization—achieved with help from the amazing Cyfrin team—that this "typical" reentrancy attack couldn’t fully drain the contract as expected. Let’s break it down!

The Vulnerable Code
Here’s the function that caught my attention:

### The Vulnerable Code
Here’s the function that caught my attention:
```solidity
function withdrawFunds() external {
    uint256 divisor = beneficiaries__ArrayOfAddresses.length;
    uint256 ethAmountAvailable = address(this).balance;
    uint256 amountPerBeneficiary = ethAmountAvailable / divisor;

    for (uint256 i = 0; i < divisor; i++) {
        address payable beneficiary = payable(beneficiaries__ArrayOfAddresses[i]);
        (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
        require(success, "something went wrong");
    }
}
```

At first glance, this looks like a classic reentrancy attack target:

An external call (beneficiary.call) transfers ETH.
* The call happens inside a loop, potentially allowing a malicious contract to re-enter and drain funds before the loop completes.
* The plan: Trigger the receive() function in a malicious contract to re-enter withdrawFunds() and siphon ETH until the contract is drained. Simple, right? Not quite.

### The Theoretical Attack Trace
Here’s my initial theoretical breakdown of the attack, assuming:

* Contract balance: 30e18 (30 ETH)
* Attacker balance: 1e18 (1 ETH)
* beneficiaries__ArrayOfAddresses.length = 4
* Attacker’s address is at index 0 in the array.

#### Round 1
1. Attacker calls withdrawFunds().
2. ethAmountAvailable = 30e18, amountPerBeneficiary = 30e18 / 4 = 7.5e18.
3. Contract sends 7.5e18 to the attacker (index 0).
4. Attacker’s receive() function re-enters withdrawFunds().

#### Round 2
5. Contract balance is now 30e18 - 7.5e18 = 22.5e18.
6. ethAmountAvailable = 22.5e18, amountPerBeneficiary = 22.5e18 / 4 = 5.625e18.
7. Attacker receives 5.625e18, total gained = 7.5e18 + 5.625e18 = 13.125e18.
8. Other beneficiaries (indices 1-3) each receive 5.625e18.

`Theoretically, I could keep re-entering, but something went wrong—my tests kept reverting with OutOfFunds. Why?`

### Debugging with Forge
To crack this, I set up a test environment:

1. mkdir reentrancy-in-loop
2. forge init --no-commit
3. Wrote a PoC and ran forge test -vv.

Here’s the output (abridged for clarity):
```bash
Ran 1 test for test/ReentrantOfArrayOfAddressesTest.t.sol
[FAIL: revert: something went wrong] testReentrancyAttackBeneficiaries() (gas: 245329)

Logs:
  [*] Before Attack:
  [*] Contract balance: 30e18
  [*] Attacker balance: 1e18

  [*] Reentrancy call #1 | Contract balance: 22.5e18
  [*] amountPerBeneficiary: 7.5e18

  [*] Reentrancy call #2 | Contract balance: 16.875e18
  [*] amountPerBeneficiary: 5.625e18
  [*] Attacker balance: 14.125e18
  [*] Other beneficiaries: 5.625e18 each

  [*] Success: true (for beneficiaries 1-3)
  [*] Success: false (revert on final call)
  ```
  The attack partially succeeded—the attacker got more `ETH (14.125e18)` than the others `(5.625e18 each)`—but the contract reverted before the first call context could complete. Why?

### The Revelation (Thanks, Cyfrin!)
After hours of solo debugging, I reached out to Pips from the Cyfrin team—a Solidity engineer who helped me crack this puzzle.

Here’s what we discovered:

1. First Call Context: When `withdrawFunds()` is called, the EVM creates a call context. The contract calculates `amountPerBeneficiary = 7.5e18` and sends it to the attacker.
2.Reentrancy: The attacker re-enters `withdrawFunds()`. A new call context is created with `amountPerBeneficiary = 5.625e18`. This completes successfully, sending funds to all beneficiaries.
3. Return to First Context: After the reentrant call finishes, the EVM returns to the original call context to finish the loop. However:
* Contract balance is now too low (e.g., 0 or insufficient funds).
* It tries to send `7.5e18` to the remaining beneficiaries, but there’s not enough ETH left.
4. Revert: The `require(success)` fails due to `OutOfFunds`, halting the attack.

In short: The contract can’t be fully drained because the original call context requires more funds than remain after reentrancy.

<p style="background-color: black; display: inline-block; padding: 5px;">
  <img src="2025_03_inheritable_smart_contract_wallet.png" alt="Orbiter Finance" style="width: 800px;" />
</p>

### Key Takeaways
1. Reentrancy Isn’t Always a Full Drain: Even with a vulnerable external call in a loop, the attack may fail due to insufficient funds in the original context.
2. Debugging is King: Theoretical traces are great, but tools like forge test -vv reveal the real story.
Ask for Help: Collaboration with brilliant engineers (shoutout to Pips from Cyfrin!) can turn confusion into clarity.
3. How to Reproduce

Clone this repo:
```bash 
git clone https://github.com/0xkoiner/reentrancy-in-loop.git
cd reentrancy-in-loop
```

Initialize Foundry:
```bash 
forge init --no-commit
```

Run the tests:
```bash 
forge test -vv
```

Scope:
```bash
├── src
    ├── attack
        ├── Reentrancy.sol
    ├── ArrayOfAddresses.sol

├── test
    ├── ReentrantOfArrayOfAddressesTest.t.sol
```

