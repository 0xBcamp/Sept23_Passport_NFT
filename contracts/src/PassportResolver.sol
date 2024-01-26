// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IEAS, Attestation} from "@ethereum-attestation-service/contracts/IEAS.sol";
import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {SchemaResolver} from "@ethereum-attestation-service/contracts/resolver/SchemaResolver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PassportResolver is SchemaResolver, ERC721, ERC721URIStorage, Ownable {
    /// @dev This struct is used to store passport details.
    struct Passport {
        string name; // Name of the passport holder
        string placeOfBirth; // Place of birth of the passport holder
        uint256 dateOfBirth; // Date of birth of the passport holder
        uint256 issueDate; // Issue date of the passport
    }

    /// @param user The user address for which the passport is created
    event PassportCreated(address user);

    error InsufficientAmount();
    error PassportCannotBeTransfered();
    error Unauthorized(address);
    error AlreadyAuthorized(address);
    error AlreadyUnauthorized(address);
    error CannotAuthorizeZeroAddress();
    error PassportNotMinted();
    error PassportAlreadyMinted();
    error TransferFailed();

    uint256 public constant MINT_PRICE = 0.08 ether;

    uint256 private _nextTokenId;
    address[] private _authorizedMembers;

    /// @notice This mapping stores the index of each member in the authorized members array.
    mapping(address member => uint256 id) private _memberIndex;
    /// @notice This mapping stores whether each member is authorized or not.
    mapping(address member => bool authorzied) private _isAuthorzedMember;
    /// @notice This mapping stores the Passport ID associated with each user address.
    mapping(address user => uint256 userId) userToPassportId;
    /// @notice This mapping stores the Passport details associated with each Passport ID.
    mapping(uint256 userId => Passport passport) passportIdToUser;

    modifier onlyAuthorized(address member) {
        if (!_isAuthorzedMember[member]) {
            revert Unauthorized(member);
        }
        _;
    }

    constructor(
        IEAS eas,
        address[] memory initialMembers
    ) ERC721("PassportNFT", "MTK") Ownable(msg.sender) SchemaResolver(eas) {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            address member = initialMembers[i];
            if (member == address(0)) {
                continue;
            }
            _authorizedMembers.push(member);
            _isAuthorzedMember[member] = true;
        }
    }

    /**
     * @dev ETH callback.
     * @dev Overrides the receive function in the SchemaResolver contract.
     */
    receive() external payable override {
        (bool success, ) = msg.sender.call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @notice The owner can withdraw the balance of the contract by calling this function.
     */
    function withdraw() external onlyOwner {
      (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @notice This function is used to authorize a member.
     * @param member The address of the member to be authorized.
     */
    function authorize(address member) external onlyAuthorized(msg.sender) {
        if (member == address(0)) {
            revert CannotAuthorizeZeroAddress();
        }
        if (_isAuthorzedMember[member]) {
            revert AlreadyAuthorized(member);
        }

        _authorizedMembers.push(member);
        _isAuthorzedMember[member] = true;
    }

    /**
     * @notice This function is used to remove a member's authority.
     * @param member The address of the member to be removed.
     */
    function unauthorize(address member) external onlyAuthorized(msg.sender) {
        if (!_isAuthorzedMember[member]) {
            revert AlreadyUnauthorized(member);
        }
        uint256 indexToRemove = _memberIndex[member];
        address lastMember = _authorizedMembers[_authorizedMembers.length - 1];

        _authorizedMembers[indexToRemove] = lastMember;
        _memberIndex[lastMember] = indexToRemove;

        _authorizedMembers.pop();
        delete _isAuthorzedMember[member];
        delete _memberIndex[member];
    }

    /**
     * @notice This function is used to get all authorized members.
     * @return An array of addresses of all authorized members.
     */
    function getAllAuthorizedMembers()
        external
        view
        returns (address[] memory)
    {
        return _authorizedMembers;
    }

    /**
     * @notice This function is used to check if a member is authorized.
     * @param member The address of the member to be checked.
     * @return A boolean indicating whether the member is authorized or not.
     */
    function isAuthorzedMember(address member) external view returns (bool) {
        return _isAuthorzedMember[member];
    }

    /**
     * @notice Returns the passport details for a user.
     * @dev Reverts if the user does not have a passport.
     * @return name The name of the passport holder.
     * @return placeOfBirth The place of birth of the passport holder.
     * @return dateOfBirth The date of birth of the passport holder.
     * @return issueDate The issue date of the passport.
     */
    function getPassport()
        external
        view
        returns (
            string memory name,
            string memory placeOfBirth,
            uint256 dateOfBirth,
            uint256 issueDate
        )
    {
        uint256 passportId = userToPassportId[msg.sender];
        if (passportId == 0) {
            revert PassportNotMinted();
        }
        Passport memory passport = passportIdToUser[passportId];
        name = passport.name;
        placeOfBirth = passport.placeOfBirth;
        dateOfBirth = passport.dateOfBirth;
        issueDate = passport.issueDate;
    }

    /**
     * @notice Creates a new Passport NFT for the sender.
     * @dev Only allows creating a passport if the sender has not created one before.
     * @param _name Name of the passport holder.
     * @param _placeOfBirth Place of birth of the passport holder.
     * @param _dateOfBirth Date of birth of the passport holder.
     * @param uri Token URI for the new passport NFT.
     */
    function createPassport(
        string calldata _name,
        string calldata _placeOfBirth,
        uint256 _dateOfBirth,
        string memory uri
    ) public payable {
        if (userToPassportId[msg.sender] != 0) {
            revert PassportAlreadyMinted();
        }
        if (msg.value < MINT_PRICE) {
            revert InsufficientAmount();
        }

        uint256 tokenId = ++_nextTokenId;
        passportIdToUser[tokenId] = Passport({
            name: _name,
            placeOfBirth: _placeOfBirth,
            dateOfBirth: _dateOfBirth,
            issueDate: block.timestamp
        });
        userToPassportId[msg.sender] = tokenId;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit PassportCreated(msg.sender);
    }

    /**
     * @notice Transfers a token from one address to another.
     * @dev Overrides the transferFrom function in the ERC721 contract. Reverts if the sender and recipient are not the zero address.
     * @dev This function is making sure that the Passport cannot be transfered from one address to another after it is minted.
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
            revert PassportCannotBeTransfered();
        }
        super.transferFrom(from, to, tokenId);
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
     * @notice This function is used to handle attestations.
     * @dev It returns a boolean indicating whether the attestation is valid or not.
     * @param attestation The attestation to be handled.
     * @return A boolean indicating whether the attestation is valid or not.
     */
    function onAttest(
        Attestation calldata attestation,
        uint256 /* value */
    ) internal view override returns (bool) {
        if (!_isAuthorzedMember[attestation.attester]) {
            revert Unauthorized(attestation.attester);
        }
        uint256 passportId = userToPassportId[attestation.recipient];
        if (passportId == 0) {
            revert PassportNotMinted();
        }
        return true;
    }

    /**
     * @notice This function is used to check if an attestation is authorized.
     * @dev It returns a boolean indicating whether the attestation is authorized or not.
     * @return A boolean indicating whether the attestation is authorized or not.
     */
    function onRevoke(
        Attestation calldata /* attestation */,
        uint256 /* value */
    ) internal virtual override returns (bool) {
        return false;
    }
}
