// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Reentrancy} from "src/attack/Reentrancy.sol";
import {ArrayOfAddresses} from "src/ArrayOfAddresses.sol";
import {Test, console2 as console} from "forge-std/Test.sol";

contract ReentrantOfArrayOfAddressesTest is Test {
    Reentrancy reentrancyContract;
    ArrayOfAddresses arrayOfAddressesContract;
    
    address[4] public addressesTest;
    address public BOB = makeAddr("BOB");

    function setUp() public {
        reentrancyContract = new Reentrancy(address(0));
        
        addressesTest[0] = address(reentrancyContract);

        for (uint256 i = 1; i < 4; i++) {
            console.log("[*] Setting up Beneficiary:", i);
            address middleAddr = makeAddr(string(abi.encodePacked("User", vm.toString(i))));
            addressesTest[i] = middleAddr;
        }

        arrayOfAddressesContract = new ArrayOfAddresses(addressesTest);
        reentrancyContract.setTarget(address(arrayOfAddressesContract));

        vm.deal(address(reentrancyContract), 1e18);
        vm.deal(address(arrayOfAddressesContract), 30e18);
    }

    function printBalances() public view {
        for (uint256 i = 0; i < 4; i++) {
            console.log("[*]ReentrantOfArrayOfAddressesTest::Address %d | Balance: %d", i, addressesTest[i].balance);
        }
        console.log("[*]ReentrantOfArrayOfAddressesTest::arrayOfAddressesContract | Balance: %d", address(arrayOfAddressesContract).balance);
        console.log("[*]ReentrantOfArrayOfAddressesTest::reentrancyContract | Balance: %d", address(reentrancyContract).balance);
    }

    function testReentrancyAttackBeneficiaries() public {
        console.log("");
        console.log("");
        console.log("[*]------------------------------------------------[*]");
        console.log("[*]------------------------------------------------[*]");
        console.log("[*]ReentrantOfArrayOfAddressesTest::Before Attack:");
        printBalances();

        vm.startPrank(BOB);
        reentrancyContract.attack();
        vm.stopPrank();

        console.log("");
        console.log("");
        console.log("[*]------------------------------------------------[*]");
        console.log("[*]------------------------------------------------[*]");

        console.log("[*]ReentrantOfArrayOfAddressesTest::After Attack:");
        for (uint256 i = 0; i < 4; i++) {
            console.log("[*]ReentrantOfArrayOfAddressesTest::Address: ", addressesTest[i]);
            console.log("[*]ReentrantOfArrayOfAddressesTest::Address %d | Balance: %de18", i, addressesTest[i].balance);
        }
        console.log("[*]ReentrantOfArrayOfAddressesTest::arrayOfAddressesContract | Balance: %d", address(arrayOfAddressesContract).balance );
        console.log("[*]ReentrantOfArrayOfAddressesTest::reentrancyContract | Balance: %d", address(reentrancyContract).balance );
    }
}