//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/Eventix.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract EventixTest is Test,EIP712{
    Eventix private eventix;
    address private minter;
    address private dummyAddress1;
    address private dummyAddress2;
    event TicketResale(address seller, address buyer, uint256 ticketId);

    constructor()EIP712("Eventix","1.00"){}


    function setUp() public {
        // Set up dummy addresses
        minter = address(0x123);
        dummyAddress1 = address(0x456);
        dummyAddress2 = address(0x789);

        // Deploy the Eventix contract
        eventix = new Eventix(minter);

        // Assign roles or set initial state if necessary
        // e.g., eventix.grantRole(eventix.MINTER_ROLE(), minter);
    }

    function testFuzzTicketMint(uint256 _price, uint8 _tier, uint256 _date, uint256 numDaysToEvent) public {
        // Skipping extreme values
        vm.assume(_price > 0 && _price < 1 ether);
        vm.assume(_tier < 3); // Only 0, 1, 2 are valid tiers
        vm.assume(_date > block.timestamp && _date < block.timestamp + 365 days); // Within a year
        vm.assume(numDaysToEvent > 0 && numDaysToEvent < 365);

        address to = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp)))));
        string memory tokenURI = "dummyURI";

        vm.prank(minter);
        uint256 tokenId = eventix.ticketMint(_price, Eventix.Tier(_tier), _date, numDaysToEvent, payable(to), tokenURI);

        // Assertions
        assertEq(eventix.ownerOf(tokenId), to);
        (, Eventix.Tier tier, uint256 basePrice, uint256 date, uint256 initialTimeToEvent, address payable owner) = eventix.idToTicketInfo(tokenId);
        assertEq(uint256(tier), _tier);

        // Assert that the ticket is valid
        assertTrue(eventix.isValid(tokenId));

        // Additional assertions
        assertEq(basePrice, _price);
        assertEq(date, _date);
        assertEq(initialTimeToEvent, block.timestamp + (numDaysToEvent * 1 days));
        assertEq(owner, to);

        // Assert correct token URI
        assertEq(eventix.tokenURI(tokenId), tokenURI);

        // Assert correct price mapping for tiers
        if(_tier == uint8(Eventix.Tier.Gold)) {
            assertEq(eventix.tierToPrice(Eventix.Tier.Gold), _price);
        } else if(_tier == uint8(Eventix.Tier.Platinum)) {
            assertEq(eventix.tierToPrice(Eventix.Tier.Platinum), _price + ((_price * 20) / 100));
        } else if(_tier == uint8(Eventix.Tier.Diamond)) {
            assertEq(eventix.tierToPrice(Eventix.Tier.Diamond), _price + ((_price * 50) / 100));
        }

        // Assert the increment of token counter
        assertEq(eventix.tokenCounters(), tokenId);
    }
    
    function testFuzzTicketResale(uint256 _price, uint8 _tier, uint256 _date, uint256 numDaysToEvent, address _seller, address _buyer) public {
        // Skipping invalid scenarios
        vm.assume(_seller != address(0) && _buyer != address(0) && _seller != _buyer);
        vm.assume(_price > 0 && _price < 1 ether);

        // Set up a ticket for testing
        string memory tokenURI = "dummyURI";

        vm.startPrank(minter);
        uint256 _ticketId = eventix.ticketMint(_price, Eventix.Tier(_tier), _date, numDaysToEvent, payable(_seller), tokenURI);
        vm.stopPrank();

        // Create the sale object
        ISale.Sale memory sale = ISale.Sale({seller: _seller, buyer: _buyer, ticketId: _ticketId, price: _price});

        // Encode the sale data for EIP712 signature
        bytes32 structHash = keccak256(abi.encode(
            eventix.SALE_TYPEHASH(),
            sale.seller,
            sale.buyer,
            sale.ticketId,
            sale.price
        ));

        // Sign the digest using the seller's private key
        // In a testing environment, simulate the signature
        bytes32 digest = _hashTypedDataV4(structHash);
        bytes memory signature = signWithPrivateKey(digest, _seller);

        // Simulate sale and transfer
        vm.prank(_seller);
        eventix.ticketSale(sale, signature);

        // Assertions
        assertEq(eventix.ownerOf(_ticketId), _buyer);

    // Additional assertions can be added here
    }

    function signWithPrivateKey(bytes32 digest, address signerAddress) internal pure returns (bytes memory) {
        // Simulate the signing using Foundry's vm.sign, which returns (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint160(signerAddress), digest);

        // Combine v, r, and s components into a single bytes signature
        return abi.encodePacked(r, s, v);
    }


    function invariantMetadata() public {
        // Ensure that the total number of tickets always equals tokenCounter
        assertEq(eventix.totalSupply(), eventix.tokenCounters());

        // Check that all tickets in the pool are valid
        for (uint i = 0; i < eventix.getTicketsInThePool(); i++) {
            uint256 ticketId = eventix.ticketsInThePool(i);
            assertTrue(eventix.isValid(ticketId));

            // Ensure the owner of each ticket in the pool is the Eventix contract itself
            assertEq(eventix.ownerOf(ticketId), address(eventix));
        }

        // Additional invariants
        // Check consistency in ticket information mapping
        for (uint256 j = 1; j <= eventix.tokenCounters(); j++) {
            if (eventix.isValid(j)) {
                (uint256 id, , uint256 basePrice, , , address owner) = eventix.idToTicketInfo(j);
                assertEq(j, id); // ID in the mapping should match the counter value
                assertTrue(basePrice > 0); // Base price should always be positive
                assertTrue(owner != address(0)); // Owner address should be valid

                // Ensure the tokenIdToAddress mapping matches the ownerOf function
                assertEq(eventix.tokenIdToAddress(j), owner);
                assertEq(eventix.ownerOf(j), owner);
            }
        }

        // Check role assignments (e.g., MINTER_ROLE should be assigned and valid)
        assertTrue(eventix.hasRole(eventix.MINTER_ROLE(), minter));

    }


}