// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PassportResolverScript} from "../script/PassportResolver.s.sol";
import {PassportResolver} from "../src/PassportResolver.sol";

contract PassportResolverTest is Test {
    PassportResolver passportResolver;
    address member;
    address bob = makeAddr("user");
    address sam = makeAddr("sam");
    uint256 mintPrice;

    string name = "John Doe";
    string placeOfBirth = "USA";
    string tokenURI = "ipfs://QmUcrJjHriyMAap8DDeNTRaZrhnPYUf9EwhjwrD5RdmCWP";
    uint256 dateOfBirth = 1694725470;

    modifier createPassport() {
        hoax(bob, 2 ether);
        passportResolver.createPassport{value: mintPrice}(
            name,
            placeOfBirth,
            dateOfBirth,
            tokenURI
        );
        _;
    }

    function setUp() public {
        PassportResolverScript script = new PassportResolverScript();
        passportResolver = script.run();
        member = passportResolver.getAllAuthorizedMembers()[0];
        mintPrice = passportResolver.MINT_PRICE();
        vm.broadcast();
    }

    function testCreatePassport() public createPassport {
        vm.prank(bob);
        (
            string memory _name,
            string memory _placeOfBirth,
            uint256 _dateOfBirth,

        ) = passportResolver.getPassport();
        assertEq(_name, name);
        assertEq(_dateOfBirth, dateOfBirth);
        assertEq(_placeOfBirth, placeOfBirth);
    }

    function testCannotCreateMoreThanOnePassport() public createPassport {
        vm.expectRevert(PassportResolver.PassportAlreadyMinted.selector);
        testCreatePassport();
    }

    function testCannotCreateIfInsufficientAmount() public {
        hoax(bob, 1 ether);
        vm.expectRevert(PassportResolver.InsufficientAmount.selector);
        passportResolver.createPassport{value: 0.02 ether}(
            name,
            placeOfBirth,
            dateOfBirth,
            tokenURI
        );
    }

    function testCannotTranferToken() public createPassport {
        vm.startPrank(bob);
        vm.expectRevert(PassportResolver.PassportCannotBeTransfered.selector);
        passportResolver.safeTransferFrom(bob, sam, 1);
        vm.stopPrank();
    }

    function testAuthorize(address toAuthorize) public {
        vm.startPrank(member);
        passportResolver.authorize(toAuthorize);

        bool isAuthorized = passportResolver.isAuthorzedMember(toAuthorize);
        assertEq(isAuthorized, true);
        vm.stopPrank();
    }

    function testCannotAuthorizeIfNotMember() public {
        vm.prank(sam);
        vm.expectRevert(
            abi.encodeWithSelector(PassportResolver.Unauthorized.selector, sam)
        );
        passportResolver.authorize(sam);
    }

    function testRemoveAuthority() public {
        vm.startPrank(member);
        passportResolver.authorize(sam);
        passportResolver.unauthorize(sam);
        bool isAuthorized = passportResolver.isAuthorzedMember(sam);
        vm.stopPrank();
        assertEq(isAuthorized, false);
    }

    function testCannotUnauthorizeIfAlreadyUnauthorized() public {
        vm.startPrank(member);
        vm.expectRevert(
            abi.encodeWithSelector(
                PassportResolver.AlreadyUnauthorized.selector,
                sam
            )
        );
        passportResolver.unauthorize(sam);
        vm.stopPrank();
    }

    function testCannotUnauthorizeIfNotMember() public {
        vm.prank(sam);
        vm.expectRevert(
            abi.encodeWithSelector(PassportResolver.Unauthorized.selector, sam)
        );
        passportResolver.unauthorize(sam);
    }

    function testGetAllAuthorizedMembers() public {
        address[] memory authorizedMembers = passportResolver
            .getAllAuthorizedMembers();
        assertEq(authorizedMembers[0], member);
    }

    function testIsAuthorizedMember() public {
        bool isMemberAuthorized = passportResolver.isAuthorzedMember(member);
        bool isSamAuthorized = passportResolver.isAuthorzedMember(sam);

        assertEq(isMemberAuthorized, true);
        assertEq(isSamAuthorized, false);
    }

    function testCannotGetPassportIfNotPassportHolder() public {
        vm.prank(bob);
        vm.expectRevert(PassportResolver.PassportNotMinted.selector);
        passportResolver.getPassport();
    }

    function testCannotTransferPassport() public createPassport {
        vm.expectRevert(PassportResolver.PassportCannotBeTransfered.selector);
        passportResolver.transferFrom(bob, sam, 1);
    }

    function testTokenURI() public createPassport {
        string memory _tokenURI = passportResolver.tokenURI(1);
        assertEq(_tokenURI, tokenURI);
    }

    function testReceive() public {
        uint256 initialBalance = address(this).balance;
        uint256 sendValue = 100;

        bool success = payable(address(passportResolver)).send(sendValue);
        require(!success);

        assertEq(address(this).balance, initialBalance);
    }
}
