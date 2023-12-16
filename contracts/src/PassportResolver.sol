// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IEAS, Attestation} from "@ethereum-attestation-service/contracts/IEAS.sol";
import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {SchemaResolver} from "@ethereum-attestation-service/contracts/resolver/SchemaResolver.sol";

contract PassportResolver is SchemaResolver, ERC721, ERC721URIStorage {
    /// @dev This struct is used to store passport details.
    struct Passport {
        string name; // Name of the passport holder
        string placeOfBirth; // Place of birth of the passport holder
        uint256 dateOfBirth; // Date of birth of the passport holder
        uint256 issueDate; // Issue date of the passport
    }

    /// @param user The user address for which the passport is created
    /// @notice This event is emitted when a new Passport is created.
    event PassportCreated(address user);

    /// @notice This error is emitted when a transfer of a Passport NFT is attempted.
    /// @dev Passports cannot be transferred.
    error PassportCannotBeTransfered();

    /// @notice This error is emitted when the sender is not authorized.
    /// @dev The sender must be authorized to perform this operation.
    error Unauthorized(address);

    /// @notice This error is emitted when the member is already authorized.
    /// @dev A member cannot be authorized more than once.
    error AlreadyAuthorized(address);

    /// @notice This error is emitted when the member is already not authorized.
    /// @dev A member cannot be unauthorized if it's already not an authorized member.
    error AlreadyUnauthorized(address);

    /// @notice This error is emitted when an attempt is made to authorize the zero address.
    /// @dev The zero address cannot be authorized.
    error CannotAuthorizeZeroAddress();

    /// @notice This error is emitted when an operation is attempted on a Passport NFT that hasn't been minted yet.
    /// @dev A passport must be minted before it can be used.
    error PassportNotMinted();

    /// @notice This error is emitted when an attempt is made to mint a passport for an address that has already been minted.
    /// @dev A passport cannot be minted more than once for the same address.
    error PassportAlreadyMinted();

    /// @notice This error is emitted when the transfer of ether fails
    /// @dev Any ETH amount sent directly to the contract is automatically sent back
    error TransferFailed();

    /// @notice This variable stores the ID to be assigned to the next Passport NFT that gets minted.
    uint256 private _nextTokenId;
    /// @notice This variable stores the addresses of all authorized members.
    address[] private _authorizedMembers;
    /// @notice This mapping stores the index of each member in the authorized members array.
    mapping(address member => uint256 id) private _memberIndex;
    /// @notice This mapping stores whether each member is authorized or not.
    mapping(address member => bool authorzied) private _isAuthorzedMember;
    /// @notice This mapping stores the Passport ID associated with each user address.
    mapping(address user => uint256 userId) userToPassportId;
    /// @notice This mapping stores the Passport details associated with each Passport ID.
    mapping(uint256 userId => Passport passport) passportIdToUser;

    /// @dev This modifier checks if the member is authorized.
    modifier onlyAuthorized(address member) {
        if (!_isAuthorzedMember[member]) {
            revert Unauthorized(member);
        }
        _;
    }

    constructor(
        IEAS eas,
        address[] memory initialMembers
    ) ERC721("PassportNFT", "MTK") SchemaResolver(eas) {
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
     * @param passportHolder The address of the passport holder (owner)
     * @param _name Name of the passport holder.
     * @param _placeOfBirth Place of birth of the passport holder.
     * @param _dateOfBirth Date of birth of the passport holder.
     * @param uri Token URI for the new passport NFT.
     */
    function createPassport(
        address passportHolder,
        string calldata _name,
        string calldata _placeOfBirth,
        uint256 _dateOfBirth,
        string memory uri
    ) public onlyAuthorized(msg.sender) {
        if (userToPassportId[passportHolder] != 0) {
            revert PassportAlreadyMinted();
        }

        uint256 tokenId = ++_nextTokenId;
        passportIdToUser[tokenId] = Passport({
            name: _name,
            placeOfBirth: _placeOfBirth,
            dateOfBirth: _dateOfBirth,
            issueDate: block.timestamp
        });
        userToPassportId[passportHolder] = tokenId;
        _safeMint(passportHolder, tokenId);
        _setTokenURI(tokenId, uri);
        emit PassportCreated(passportHolder);
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
