// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//Errors
error Eventix__OnlySellerCanEncode();

contract Eventix is ERC721,EIP712,AccessControl{
    using ECDSA for bytes32;

    //Enum
    enum Tier{
        Gold,
        Platinum,
        Diamond
    }

    //Struct
    struct TicketInfo{
        uint256 id;
        Tier tier;
        uint256 price;
        uint256 date;
        address owner;
    }

    struct Sale{
        address seller;
        address buyer;
        uint256 ticketId;
        uint256 price;
    }

    //state variables
    string public  _name;
    uint256 public tokenCounters=0;
    bytes32 public constant MINTER_ROLE=keccak256("MINTER_ROLE");
    bytes32 public constant SALE_TYPEHASH=keccak256("Sale(address seller,address buyer,uint256 tokenId,uint256 price)");

    //mappiing
    mapping(uint256 => bool)public tokenIdExists;
    mapping(Tier => uint256)public tierToPrice;
    mapping(uint256 => TicketInfo) public idToTicketInfo;
    mapping(uint256 => address) public tokenIdToAddress;

    //Events
    event TicketMinted(uint256 _price,Tier _tier,uint256 _tokenId,uint256 _date,address _to);

    //modifiers
    modifier onlySeller(uint256 _tokenId){
        if(ownerOf(_tokenId)!=msg.sender){
            revert Eventix__OnlySellerCanEncode();
        }
        _;
    }


    constructor(address _minter)ERC721("Eventix","EVX")EIP712("Eventix","1.00"){
        _name="Eventix";
        _grantRole(MINTER_ROLE,_minter);
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    //Function for initial mint of Tickets
    function ticketMint(
        uint256 _price,
        Tier _tier,
        uint256 _date,
        address _to
        )
        public onlyRole(MINTER_ROLE)
    {
        tierToPrice[Tier.Gold]=_price;
        tierToPrice[Tier.Platinum]=_price+((_price*20)/100);
        tierToPrice[Tier.Diamond]=_price + ((_price*50)/100);

        uint256 tokenId=uint256(keccak256(abi.encodePacked(block.timestamp,_to,tokenCounters)));

        //mintingNFT
        _mint(_to,tokenId);

        //recording ticket details
        idToTicketInfo[tokenId]=TicketInfo(tokenId,_tier,tierToPrice[_tier],_date,_to);
        tokenIdToAddress[tokenId]=_to;
        tokenIdExists[tokenId]=true;

        tokenCounters++;
        emit TicketMinted(tierToPrice[_tier],_tier,tokenId,_date,_to);
    }

    function encodeSale(Sale calldata sale)
    public view onlySeller(sale.ticketId)
    returns(bytes memory)
    {
        return abi.encode(
            SALE_TYPEHASH,
            sale.buyer,
            sale.seller,
            sale.ticketId,
            sale.price
        );
    }

    function ticketSale(
        Sale calldata sale,
        bytes calldata signature
        ) 
        external onlySeller(sale.ticketId) 
    {
        require(ownerOf(sale.ticketId)==sale.seller,"only owner can sell their NFTs");

        address signer = _hashTypedDataV4(
            keccak256(encodeSale(sale))
        ).recover(signature);   

        require(signer==ownerOf(sale.ticketId),"Only owner can be the signer"); 

        safeTransferFrom(sale.seller,sale.buyer,sale.ticketId);
    }


    function supportsInterface(bytes4 interfaceId) public view override(AccessControl,ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}