// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PassportResolver, IEAS} from "../src/PassportResolver.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract PassportResolverScript is Script {
    address[] initialMembers;
    address member = 0x3b321410aC522A20280073b57d1c8e3cA29B1A96;

    function run() public returns (PassportResolver) {
        HelperConfig config = new HelperConfig();
        (address eas, ) = config.activeNetworkConfig();

        initialMembers.push(member);

        vm.startBroadcast();
        PassportResolver passportResolver = new PassportResolver(IEAS(eas), initialMembers);
        vm.stopBroadcast();

        return passportResolver;
    }
}
