// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PassportNFTScript} from "../script/PassportNFT.s.sol";
import {PassportNFT} from "../src/PassportNFT.sol";

contract PassportNftTest is Test {
    PassportNFT passportNft;
    address user = makeAddr("user");
    address bob = makeAddr("bob");

    string name = "John Doe";
    string placeOfBirth = "USA";
    string tokenURI = "ipfs://QmUcrJjHriyMAap8DDeNTRaZrhnPYUf9EwhjwrD5RdmCWP";
    uint256 dateOfBirth = 1694725470;
    uint256 socialSecurityNumber = 987654321;
    uint256 driversLicenceNumber = 123456789;

    modifier createPassport() {
        vm.prank(user);
        passportNft.createPassport(
            name,
            placeOfBirth,
            dateOfBirth,
            socialSecurityNumber,
            driversLicenceNumber,
            tokenURI
        );
        _;
    }

    function setUp() public {
        PassportNFTScript script = new PassportNFTScript();
        passportNft = script.run();
        vm.broadcast();
    }

    function testCreatePassport() public createPassport {
        vm.prank(user);
        uint256 passportId = passportNft.getPassportId(user);
        assertEq(passportId, 1);
    }

    function testCannotCreateMoreThanOnePassport() public createPassport {
        vm.expectRevert(
            PassportNFT.PassportNFT__PassportAlreadyMinted.selector
        );
        testCreatePassport();
    }

    function testCannotTranferToken() external createPassport {
        vm.startPrank(user);
        vm.expectRevert(
            PassportNFT.PassportNFT__PassportCannotBeTransfered.selector
        );
        passportNft.safeTransferFrom(user, bob, 1);
        vm.stopPrank();
    }

    function testGrantStamp() external createPassport {
        vm.prank(user);
        bytes32 attestationUID = passportNft.createStamp("John Doe", "India");
        bytes32 stamp = passportNft.getStamps(user)[0];
        assertEq(attestationUID, stamp);
    }

    function testCannotGrantStampWithoutPassport() external {
        vm.prank(user);
        vm.expectRevert(PassportNFT.PassportNFT__PassportNotMinted.selector);
        passportNft.createStamp("John Doe", "Australia");
    }

    function testGetPassport() external createPassport {
        vm.prank(user);
        (
            string memory _name,
            string memory _placeOfBirth,
            uint256 _dateOfBirth,
            ,
            uint256 _socialSecurityNumber,
            uint256 _driversLicenceNumber
        ) = passportNft.getPassport();
        assertEq(_name, name);
        assertEq(_placeOfBirth, placeOfBirth);
        assertEq(_dateOfBirth, dateOfBirth);
        assertEq(_socialSecurityNumber, socialSecurityNumber);
        assertEq(_driversLicenceNumber, driversLicenceNumber);
    }

    function testGetStamps() external createPassport {
        vm.startPrank(user);
        bytes32 stamp1 = passportNft.createStamp("John Doe", "India");
        bytes32 stamp2 = passportNft.createStamp("John Doe", "Australia");
        vm.stopPrank();

        bytes32[] memory stamps = passportNft.getStamps(user);
        assertEq(stamp1, stamps[0]);
        assertEq(stamp2, stamps[1]);
    }

    function testTokenURI() external createPassport {
        string memory _tokenURI = passportNft.tokenURI(1);
        assertEq(_tokenURI, tokenURI);
    }
}
