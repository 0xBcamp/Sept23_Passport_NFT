"use client";

import { Button } from "@/components/ui/button";
import { EAS_CONTRACT_ADDRESS, SCHEMA_UID } from "@/constants";
import { EAS, SchemaEncoder } from "@ethereum-attestation-service/eas-sdk";
import { ethers } from "ethers";
import { useEffect, useState } from "react";

export function CreateAttestation({ recipient }) {
  const [eas, setEas] = useState(null);

  useEffect(() => {
    const easInstance = new EAS(EAS_CONTRACT_ADDRESS);

    if (window.ethereum !== undefined) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      easInstance.connect(signer);

      console.log(signer);
      setEas(easInstance);
      console.log(signer);
    }
  }, []);

  const createAttestation = async () => {
    if (!eas) {
      return;
    }

    const arrivalTime = Date.now();

    const schemaEncoder = new SchemaEncoder(
      "string country, uint256 arrivalTime",
    );
    const encodedData = schemaEncoder.encodeData([
      { name: "country", value: "India", type: "string" },
      { name: "arrivalTime", value: arrivalTime, type: "uint256" },
    ]);

    const tx = await eas.attest({
      schema: SCHEMA_UID,
      data: {
        recipient: recipient,
        expirationTime: 0,
        revocable: false,
        data: encodedData,
      },
    });

    const newAttestationUID = await tx.wait();

    console.log("New attestation UID:", newAttestationUID);
  };

  return (
    <div>
      <Button className="w-full" type="submit" onClick={createAttestation}>
        Create Attestation
      </Button>
    </div>
  );
}
