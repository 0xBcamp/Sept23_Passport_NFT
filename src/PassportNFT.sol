// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AttestStamp} from "./AttestStamp.sol";

/**
 * @title PassportNFT
 * @notice This contract creates, manages, and transfers Passport Non-Fungible Tokens (NFTs).
 * @dev Inherits from ERC721, ERC721URIStorage, and AttestStamp.
 */
contract PassportNFT is ERC721, ERC721URIStorage, AttestStamp {
    /**
     * @title Passport
     * @notice This struct represents a Passport with all necessary details.
     * @dev It includes details like name, place of birth, date of birth, social security number, etc.
     */
    struct Passport {
        string name; // Name of the passport holder
        string placeOfBirth; // Place of birth of the passport holder
        uint256 dateOfBirth; // Date of birth of the passport holder
        uint256 issueDate; // Issue date of the passport
        uint256 socialSecurityNumber; // Social Security Number of the passport holder
        uint256 driversLicenceNumber; // Driver's License Number of the passport holder
        bytes32[] stampAttestions; // Array of attestation stamps
    }

    /// @param user @notice This event is emitted when a new Passport is created.
    event PassportCreated(address user);

    /**
     * @notice This error is emitted when a transfer of a Passport NFT is attempted.
     * @dev Passports cannot be transferred.
     */
    error PassportNFT__PassportCannotBeTransfered();
    /// @notice This error is emitted when an operation is attempted on a Passport NFT that hasn't been minted yet.
    error PassportNFT__PassportNotMinted();
    /// @notice This error is emitted when a Passport NFT is attempted to be minted by a user who already owns a Passport NFT.
    error PassportNFT__PassportAlreadyMinted();
    /// @notice This error is emitted when the details of a Passport NFT don't match the expected details.
    error PassportNFT__DetailsMismatch();

    /// @dev Mapping from user addresses to their Passport IDs.
    mapping(address user => uint256 userId) userToPassportId;
    /// @dev Mapping from Passport IDs to their corresponding Passport details.
    mapping(uint256 userId => Passport passport) passportIdToUser;
    /// @dev Stores the ID to be assigned to the next Passport NFT that gets minted.
    uint256 private _nextTokenId;

    constructor(
        address eas,
        bytes32 schemaUID
    ) ERC721("PassportNFT", "MTK") AttestStamp(eas, schemaUID) {}

    /**
     * @notice Creates a new Passport NFT for the sender.
     * @dev Only allows creating a passport if the sender has not created one before.
     * @param _name Name of the passport holder.
     * @param _placeOfBirth Place of birth of the passport holder.
     * @param _dateOfBirth Date of birth of the passport holder.
     * @param _socialSecurityNumber Social Security Number of the passport holder.
     * @param _driversLicenceNumber Driver's License Number of the passport holder.
     * @param uri Token URI for the new passport NFT.
     */
    function createPassport(
        string calldata _name,
        string calldata _placeOfBirth,
        uint256 _dateOfBirth,
        uint256 _socialSecurityNumber,
        uint256 _driversLicenceNumber,
        string memory uri
    ) public {
        if (userToPassportId[msg.sender] != 0) {
            revert PassportNFT__PassportAlreadyMinted();
        }
        uint256 tokenId = ++_nextTokenId;
        passportIdToUser[tokenId] = Passport({
            name: _name,
            placeOfBirth: _placeOfBirth,
            dateOfBirth: _dateOfBirth,
            issueDate: block.timestamp,
            socialSecurityNumber: _socialSecurityNumber,
            driversLicenceNumber: _driversLicenceNumber,
            stampAttestions: new bytes32[](0)
        });
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        userToPassportId[msg.sender] = tokenId;
        emit PassportCreated(msg.sender);
    }

    /**
     * @notice Grants a stamp to the passport holder.
     * @dev Reverts if the user does not have a passport or if the details do not match.
     * @param name Name of the passport holder.
     * @param country Country of the passport holder.
     * @return attestationUID The UID of the stamp attestation.
     */
    function grantStamp(
        string calldata name,
        string calldata country
    ) external returns (bytes32 attestationUID) {
        uint256 passportId = userToPassportId[msg.sender];
        Passport memory passport = passportIdToUser[passportId];
        if (passportId == 0) {
            revert PassportNFT__PassportNotMinted();
        }
        if (
            (bytes(name).length != bytes(passport.name).length) ||
            (keccak256(bytes(name)) != keccak256(bytes(passport.name)))
        ) {
            revert PassportNFT__DetailsMismatch();
        }
        attestationUID = makeStampAttestation(
            msg.sender,
            name,
            country,
            block.timestamp
        );
        passportIdToUser[passportId].stampAttestions.push(attestationUID);
    }

    /**
     * @notice Returns the token URI for a given token ID.
     * @dev Overrides the tokenURI function in the ERC721 contract.
     * @param tokenId The ID of the token.
     * @return The token URI.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Checks if the contract supports an interface.
     * @dev Overrides the supportsInterface function in the ERC721 contract.
     * @param interfaceId The ID of the interface.
     * @return A boolean indicating if the interface is supported.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Transfers a token from one address to another.
     * @dev Overrides the transferFrom function in the ERC721 contract. Reverts if the sender and recipient are not the zero address.
     * @param from The address to transfer the token from.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        if (from != address(0) && to != address(0)) {
            revert PassportNFT__PassportCannotBeTransfered();
        }
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Returns the passport ID associated with a user.
     * @param user The address of the user.
     * @return The passport ID.
     */
    function getPassportId(address user) external view returns (uint256) {
        return userToPassportId[user];
    }

    /**
     * @notice Returns the passport details for a user.
     * @dev Reverts if the user does not have a passport.
     * @param user The address of the user.
     * @return name The name of the passport holder.
     * @return placeOfBirth The place of birth of the passport holder.
     * @return dateOfBirth The date of birth of the passport holder.
     * @return issueDate The issue date of the passport.
     * @return socialSecurityNumber The Social Security Number of the passport holder.
     * @return driversLicenceNumber The Driver's License Number of the passport holder.
     */
    function getPassport(
        address user
    )
        external
        view
        returns (
            string memory name,
            string memory placeOfBirth,
            uint256 dateOfBirth,
            uint256 issueDate,
            uint256 socialSecurityNumber,
            uint256 driversLicenceNumber
        )
    {
        if (userToPassportId[user] == 0) {
            revert PassportNFT__PassportNotMinted();
        }
        uint256 passportId = userToPassportId[user];
        Passport memory passport = passportIdToUser[passportId];
        name = passport.name;
        placeOfBirth = passport.placeOfBirth;
        dateOfBirth = passport.dateOfBirth;
        issueDate = passport.issueDate;
        socialSecurityNumber = passport.socialSecurityNumber;
        driversLicenceNumber = passport.driversLicenceNumber;
    }

    /**
     * @notice Returns the attestation stamps for a user's passport.
     * @param user The address of the user.
     * @return stamps An array of the attestation stamps.
     */
    function getStamps(
        address user
    ) external view returns (bytes32[] memory stamps) {
        uint256 passportId = userToPassportId[user];
        Passport memory passport = passportIdToUser[passportId];
        return passport.stampAttestions;
    }
}
