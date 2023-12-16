// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PassportResolver, IEAS} from "../src/PassportResolver.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract PassportResolverScript is Script {
    PassportResolver passportResolver;
    address[] initialMembers;
    address member = 0x3b321410aC522A20280073b57d1c8e3cA29B1A96;

    function run() public returns (PassportResolver) {
        HelperConfig config = new HelperConfig();
        (address eas, ) = config.activeNetworkConfig();

        initialMembers.push(member);

        vm.startBroadcast();
        passportResolver = new PassportResolver(IEAS(eas), initialMembers);
        vm.stopBroadcast();

        return passportResolver;
    }

    function createPassport() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address passportHolder = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        string memory name = "John Doe";
        string memory placeOfBirth = "USA";
        uint256 dateOfBirth = 1694725470;
        string
            memory tokenURI = "ipfs://QmUcrJjHriyMAap8DDeNTRaZrhnPYUf9EwhjwrD5RdmCWP";

        passportResolver.createPassport(
            passportHolder,
            name,
            placeOfBirth,
            dateOfBirth,
            tokenURI
        );

        vm.stopBroadcast();
    }
}

// Receive
// Fallback
// External
// Public
// Interval
// Private

// Events
// Errors
// Modifiers
// Functions
