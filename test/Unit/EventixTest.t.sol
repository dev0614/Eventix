//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Eventix} from "../../src/Eventix.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {DeployEventix} from "../../script/DeployEventix.s.sol";
import {ISale} from "../../src/ISale.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract EventixTest is Test,EIP712{
    Eventix eventix;
    address public minter=0x66aAf3098E1eB1F24348e84F509d8bcfD92D0620;
    address alice=makeAddr("alice");
    //DeployEventix public deployer;

    
    uint256 _price=0.01 ether;
    uint256 _date=25;
    uint256 numdaysToEvent=24;
    address payable _to=payable(0xF941d25cEB9A56f36B2E246eC13C125305544283);
    uint256 toPrivKey=vm.envUint("OWNER_PRIVATE_KEY");
    string  _tokenURI="https://api.pudgypenguins.io/lil/9946";




    //Enum
    enum Tier{
        Gold,
        Platinum,
        Diamond
    }

    constructor()EIP712("Eventix","1.00"){}

    // //struct
    // struct Sale{
    //     address seller;
    //     address buyer;
    //     uint256 ticketId;
    //     uint256 price;
    // }

    //Events
    event TicketMinted(uint256 indexed _price,Tier _tier,uint256 indexed _tokenId,uint256 _date,address indexed _to);

    function setUp()public{
        //deployer=new DeployEventix();
        eventix=new Eventix(address(this));
    }
    function testFail_IfTesterMints()public{
        vm.startPrank(alice);
        eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
        vm.stopPrank();
    }
    function testIfMintedToRightAddress()public{
        eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
        address expectedOwner=_to;
        uint256 _ticketId=eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
        address actualOwner=eventix.getAddressMintedTo(_ticketId);

        assertEq(actualOwner,expectedOwner);
    }

    function testIfTicketIdIsValid()public{
        eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
        uint256 _ticketId=eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
        assert(eventix.isValid(_ticketId)==true);
        
    }

    function test_ExpectEmit_TicketMinted()public{
        eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
    }

    function testTicketSale() public {
        // Set up a ticket for testing
        uint256 _ticketId = eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );

        // Set up sale data
        address buyer = makeAddr("buyer");
        uint256 salePrice = 0.02 ether;
        ISale.Sale memory sale = ISale.Sale({
            seller: _to,
            buyer: buyer,
            ticketId: _ticketId,
            price: salePrice
        });

        bytes32 structHash = keccak256(abi.encode(
            eventix.SALE_TYPEHASH(),
            sale.seller,
            sale.buyer,
            sale.ticketId,
            sale.price
        ));

        vm.startPrank(address(_to));
        
        bytes32 digest = _hashTypedDataV4(structHash);

        // Simulate seller signing the sale
        bytes memory signature = signSale(digest, toPrivKey);

        // Execute the ticket sale
        eventix.ticketSale(sale, signature);

        // Assertions
        assertEq(eventix.ownerOf(_ticketId), buyer);
        // Additional checks for state changes, balances, etc.

        vm.stopPrank();
    }

    function signSale(bytes32 digest, uint256 privateKey ) internal pure returns (bytes memory) {
        // Simulate the signing using Foundry's vm.sign, which returns (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // Combine v, r, and s components into a single bytes signature
        return abi.encodePacked(r, s, v);
    }
}
    