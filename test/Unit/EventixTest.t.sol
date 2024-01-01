//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Eventix} from "../../src/Eventix.sol";
import {Test} from "forge-std/Test.sol";

contract EventixTest is Test{
    Eventix eventix;
    address public minter=0x66aAf3098E1eB1F24348e84F509d8bcfD92D0620;

    
    uint256 _price=0.01 ether;
    uint256 _date=25;
    uint256 numdaysToEvent=24;
    address payable _to=payable(0xF941d25cEB9A56f36B2E246eC13C125305544283);
    string  _tokenURI="https://api.pudgypenguins.io/lil/9946";

    function setUp()public{
        eventix=new Eventix(minter);
    }
    function testFail_IfTesterMints()public{
        eventix.ticketMint(
            _price,
            eventix.getTier(0),
            _date,
            numdaysToEvent,
            _to,
            _tokenURI
        );
    }
}