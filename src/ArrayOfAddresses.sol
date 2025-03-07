// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {console2 as console} from "forge-std/Test.sol";

contract ArrayOfAddresses {
    ////////////////////////////////////////////////////////////////////////////////////
    //                                    Storage                                     //
    ////////////////////////////////////////////////////////////////////////////////////
    address[4] public beneficiaries__ArrayOfAddresses;

    ////////////////////////////////////////////////////////////////////////////////////
    //                                    Constructor                                 //
    ////////////////////////////////////////////////////////////////////////////////////
    constructor(address[4] memory _addresses) {
        beneficiaries__ArrayOfAddresses = _addresses;
    }   

    ////////////////////////////////////////////////////////////////////////////////////
    //                                    Functions                                   //
    ////////////////////////////////////////////////////////////////////////////////////
    receive() external payable {}

    function withdrawFunds() external {
        console.log("");
        console.log("");
        console.log("[*]------------------------------------------------[*]");
        console.log("[*]------------------------------------------------[*]");

        uint256 divisor = beneficiaries__ArrayOfAddresses.length;
        console.log("[*]ArrayOfAddresses::divisor:", divisor);

        uint256 ethAmountAvailable = address(this).balance;
        console.log("[*]ArrayOfAddresses::ethAmountAvailable:", ethAmountAvailable);

        uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
        console.log("[*]ArrayOfAddresses::amountPerBeneficiary:", amountPerBeneficiary);

        for (uint256 i = 0; i < divisor; i++) {
            address payable beneficiary = payable(beneficiaries__ArrayOfAddresses[i]);
            console.log("[*]ArrayOfAddresses::addressArrayOfAddresses: ", beneficiary);
            console.log("");
            console.log("");
            console.log("[*]------------------------------------------------[*]");
            console.log("[*]------------------------------------------------[*]");

            (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");

            console.log("[*]ReentrantOfArrayOfAddressesTest::Address: ", beneficiaries__ArrayOfAddresses[i]);
            console.log("[*]ArrayOfAddresses::Address %d | Balance: %de18", i, beneficiaries__ArrayOfAddresses[i].balance);

            console.log("");
            console.log("");
            console.log("[*][*]ArrayOfAddresses::success:", success);
            require(success, "something went wrong");

        }
    }
}