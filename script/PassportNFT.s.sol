// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {PassportNFT} from "../src/PassportNFT.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract PassportNFTScript is Script {
    function run() public returns (PassportNFT) {
        HelperConfig config = new HelperConfig();
        (address eas, bytes32 schemaUID) = config.activeNetworkConfig();

        vm.startBroadcast();
        PassportNFT passportNft = new PassportNFT(eas, schemaUID);
        vm.stopBroadcast();

        return passportNft;
    }
}
