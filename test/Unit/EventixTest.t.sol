//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Eventix} from "../../src/Eventix.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployEventix} from "../../script/DeployEventix.s.sol";

contract EventixTest is Test{
    Eventix eventix;
    address public minter=0x66aAf3098E1eB1F24348e84F509d8bcfD92D0620;
    address alice=makeAddr("alice");
    //DeployEventix public deployer;

    
    uint256 _price=0.01 ether;
    uint256 _date=25;
    uint256 numdaysToEvent=24;
    address payable _to=payable(0xF941d25cEB9A56f36B2E246eC13C125305544283);
    string  _tokenURI="https://api.pudgypenguins.io/lil/9946";




    //Enum
    enum Tier{
        Gold,
        Platinum,
        Diamond
    }

    //struct
    struct Sale{
        address seller;
        address buyer;
        uint256 ticketId;
        uint256 price;
    }

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

    function testTicketSale()public{
    
    uint256 _ticketId=eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
    Sale memory sale=Sale({
        seller:_to,
        buyer:msg.sender,
        ticketId:_ticketId,
        price:_price
    });
    
     

    }
}