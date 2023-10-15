// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
        // address eas = 0xC2679fBD37d54388Ce493F1DB75320D236e1815e;
        // bytes32 schemaUID = 0x5efb7116bf1303a7f3df73539cfab45bc671e728c7477388b958b92826e61cc3;
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            schemaUID: 0x5efb7116bf1303a7f3df73539cfab45bc671e728c7477388b958b92826e61cc3,
            eas: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
        });
        return sepoliaConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.eas != address(0)) {
            return activeNetworkConfig;
        }

        string
            memory schema = "string name, string country, uint256 arrivalTime";
        ISchemaResolver resolver = ISchemaResolver(address(0));
        bool revocable = true;
        SchemaRegistry registry = new SchemaRegistry();
        bytes32 _schemaUID = registry.register(schema, resolver, revocable);
        IEAS _eas = new EAS(registry);

        NetworkConfig memory anvilConfig = NetworkConfig({
            schemaUID: _schemaUID,
            eas: address(_eas)
        });
        return anvilConfig;
    }
}
