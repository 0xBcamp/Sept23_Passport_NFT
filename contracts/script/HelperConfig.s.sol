// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {IEAS, EAS} from "@ethereum-attestation-service/contracts/EAS.sol";
import {SchemaRegistry, ISchemaResolver} from "@ethereum-attestation-service/contracts/SchemaRegistry.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address eas;
        bytes32 schemaUID;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        // address schemaUID: 0x32a6014fedc1de48e7ba2f24730228a21fb781abfc181ae91e0d22ec0455ddeb,
        // bytes32 eas: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            schemaUID: 0x32a6014fedc1de48e7ba2f24730228a21fb781abfc181ae91e0d22ec0455ddeb,
            eas: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
        });
        return sepoliaConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.eas != address(0)) {
            return activeNetworkConfig;
        }

        string memory schema = "string country, uint256 arrivalTime";
        ISchemaResolver resolver = ISchemaResolver(address(0));
        bool revocable = false;
        SchemaRegistry registry = new SchemaRegistry();
        bytes32 _schemaUID = registry.register(schema, resolver, revocable);

        IEAS _eas = new EAS(registry);

        NetworkConfig memory anvilConfig = NetworkConfig({
            schemaUID: _schemaUID,
            eas: address(_eas)
        });
        vm.broadcast();
        return anvilConfig;
    }
}
