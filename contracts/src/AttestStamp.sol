// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IEAS, AttestationRequest, AttestationRequestData, Attestation} from "@ethereum-attestation-service/contracts/IEAS.sol";
import {EMPTY_UID, NO_EXPIRATION_TIME} from "@ethereum-attestation-service/contracts/Common.sol";

/**
 * @title AttestStamp
 * @notice This contract is used for creating attestation stamps.
 * @dev It interacts with the Ethereum Attestation Service (EAS).
 */
contract AttestStamp {
    bytes32 public immutable schemaUID;
    IEAS private immutable _eas;

    constructor(address eas, bytes32 _schemaUID) {
        schemaUID = _schemaUID;
        _eas = IEAS(eas);
    }

    /**
     * @notice Creates a stamp attestation.
     * @dev Interacts with the EAS to create the attestation.
     * @param _recipient The recipient of the attestation.
     * @param name The name associated with the attestation.
     * @param country The country associated with the attestation.
     * @param entryTime The entry time for the attestation.
     * @return The UID of the created attestation.
     */
    function makeStampAttestation(
        address _recipient,
        string calldata name,
        string calldata country,
        uint256 entryTime
    ) internal returns (bytes32) {
        bytes32 attestationUID = _eas.attest(
            AttestationRequest({
                schema: schemaUID,
                data: AttestationRequestData({
                    recipient: _recipient,
                    expirationTime: NO_EXPIRATION_TIME,
                    revocable: false,
                    refUID: EMPTY_UID,
                    data: abi.encode(name, country, entryTime),
                    value: 0
                })
            })
        );
        return attestationUID;
    }

    /**
     * @notice Returns the details of an attestation.
     * @dev Interacts with the EAS to retrieve the attestation details.
     * @param attestationUID The UID of the attestation.
     * @return recipient The recipient of the attestation.
     * @return name The name associated with the attestation.
     * @return country The country associated with the attestation.
     * @return arrivalTime The arrival time for the attestation.
     */
    function getAttestation(
        bytes32 attestationUID
    )
        internal
        view
        returns (
            address recipient,
            string memory name,
            string memory country,
            uint256 arrivalTime
        )
    {
        Attestation memory attestation = _eas.getAttestation(attestationUID);
        recipient = attestation.recipient;
        (name, country, arrivalTime) = abi.decode(
            attestation.data,
            (string, string, uint)
        );
    }
}
