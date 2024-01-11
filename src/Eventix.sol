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

import "./ISale.sol";

//Errors
error Eventix__OnlySellerCanEncode();
error Eventix__TicketIsInvalid();

contract Eventix is ERC721,EIP712,AccessControl,ERC721URIStorage{
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
        uint256 basePrice;
        uint256 date;
        uint256 initialtimeToEvent;
        address payable owner;
    }

    // struct Sale{
    //     address seller;
    //     address buyer;
    //     uint256 ticketId;
    //     uint256 price;
    // }
    /**
     * owner
     * basePrice
     * timeToEvent
     * ticketId
     * tier
     */

    //state variables
    uint256 public tokenCounters=0;
    uint256 public poolCounter=0;
    uint256[] public ticketsInThePool;
    uint8[] public priceShift;
    bytes32 public constant MINTER_ROLE=keccak256("MINTER_ROLE");
    bytes32 public constant SALE_TYPEHASH=keccak256("Sale(address seller,address buyer,uint256 tokenId,uint256 price)");

    //mappiing
    mapping(uint256 => bool)public isValid;
    mapping(Tier => uint256)public tierToPrice;
    mapping(uint256 => TicketInfo) public idToTicketInfo;
    mapping(uint256 => address) public tokenIdToAddress;
    //mapping(uint256 => uint256) public poolCounterToId;

    //Events
    event TicketMinted(uint256 indexed _price,Tier _tier,uint256 indexed _tokenId,uint256 _date,address indexed _to);
    event TicketResale(address indexed seller,address indexed buyer,uint256 indexed ticketId);
    event TicketAddedToPool(address indexed owner,uint256 indexed _ticketId);
    event TicketSoldThroughPool(uint256 _ticketId,address buyer);

    //modifiers
    modifier onlySeller(uint256 _tokenId){
        if(ownerOf(_tokenId)!=msg.sender){
            revert Eventix__OnlySellerCanEncode();
        }
        _;
    }
    modifier isValiid(uint256 _ticketId){
        if(isValid[_ticketId]==true){
            revert Eventix__TicketIsInvalid();
        }
        _;
    }
    /**
     * 
     * 
    modifier saleValidation(){
        if(isValid[Sale.ticketId]!=false || tokenIdToAddress[Sale.ticketId]!=Sale.seller){
            revert Eventix__SaleValidationFailed();
        }
    }
     */


    constructor(address _minter)ERC721("Eventix","EVX")EIP712("Eventix","1.00"){
        _grantRole(MINTER_ROLE,_minter);
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    //Function for initial mint of Tickets
    function ticketMint(
        uint256 _price,
        Tier _tier,
        uint256 _date,
        uint256 numdaysToEvent,
        address payable _to,
        string memory _tokenURI
        )
        public onlyRole(MINTER_ROLE)
        returns(uint256)
    {
        tierToPrice[Tier.Gold]=_price;
        tierToPrice[Tier.Platinum]=_price+((_price*20)/100);
        tierToPrice[Tier.Diamond]=_price + ((_price*50)/100);

        uint256 tokenId=uint256(keccak256(abi.encodePacked(block.timestamp,_to,tokenCounters)));
        uint256 initialTimeToEvent=block.timestamp + (numdaysToEvent * 1 days);

        //mintingNFT
        _mint(_to,tokenId);

        //setting tokenURI for the minted NFT
        _setTokenURI(tokenId,_tokenURI);

        //recording ticket details
        idToTicketInfo[tokenId]=TicketInfo(tokenId,_tier,tierToPrice[_tier],_date,initialTimeToEvent,_to);
        tokenIdToAddress[tokenId]=_to;
        isValid[tokenId]=true;

        tokenCounters++;
        emit TicketMinted(tierToPrice[_tier],_tier,tokenId,_date,_to);

        return tokenId;
    }

    function encodeSale(ISale.Sale memory mySale)
    internal  view onlySeller(mySale.ticketId) 
    isValiid(mySale.ticketId)
    returns(bytes memory)
    {
        require(tokenIdToAddress[mySale.ticketId]==mySale.seller,"not the owner");
        require(mySale.buyer!=address(0),"address doesn't exist");
        return abi.encode(
            SALE_TYPEHASH,
            mySale.seller,
            mySale.buyer,
            mySale.ticketId,
            mySale.price
        );
    }

    function ticketSale(
        ISale.Sale memory mySale,
        bytes calldata signature
        ) 
        external onlySeller(mySale.ticketId) isValiid(mySale.ticketId)
    {
        require(tokenIdToAddress[mySale.ticketId]==mySale.seller,"not the owner");
        require(mySale.buyer!=address(0),"Cannot send to a null address");

        address signer = _hashTypedDataV4(
            keccak256(encodeSale(mySale))
        ).recover(signature);   

        require(signer==ownerOf(mySale.ticketId),"Only owner can be the signer"); 

        tokenIdToAddress[mySale.ticketId]=mySale.buyer;
        emit TicketResale(mySale.seller,mySale.buyer,mySale.ticketId);

        safeTransferFrom(mySale.seller,mySale.buyer,mySale.ticketId);
    }

    function addToPool(uint256 _ticketId)external isValiid(_ticketId){
        require(isValid[_ticketId]==true,"Invalid ticket Id");
        require(ownerOf(_ticketId)==msg.sender,"only owner can add ticket to the pool");

        _transfer(msg.sender,address(this),_ticketId);

        /**
         * 
        poolCounterToId[poolCounter]=_ticketId;
        poolCounter++;
         */

        ticketsInThePool.push(_ticketId);

        emit TicketAddedToPool(msg.sender,_ticketId);
    }
    function calculateNewPrice(uint256 _ticketId)public isValiid(_ticketId) returns (uint256){
        require(ownerOf(_ticketId)==address(this),"This ticket is not added to the pool");
        require(idToTicketInfo[_ticketId].initialtimeToEvent>block.timestamp,"Event already finished");

        uint256 currentTimeToEvent=idToTicketInfo[_ticketId].initialtimeToEvent-block.timestamp;
        uint256 category;

        if(currentTimeToEvent> 7 days){
            category=0;
        }
        else if(currentTimeToEvent>3 && currentTimeToEvent<=7 days){
            category=1;
        }
        else{
            category=2;
        }

        priceShift = [0, 25, 55];

        return idToTicketInfo[_ticketId].basePrice + (idToTicketInfo[_ticketId].basePrice* priceShift[category])/100;
    }

    function buyFromPool()external payable{

        uint256 _ticketId=ticketsInThePool[0];
        require(ownerOf(_ticketId)==address(this),"This ticket is not added to the pool");
        require(isValid[_ticketId]==true,"ticketId is not valid");
        uint256 ticketPrice=calculateNewPrice(_ticketId);

        require(msg.value>=ticketPrice,"Have to send the ticketPrice at least");

        _transfer(address(this),msg.sender,_ticketId);
        address payable seller=idToTicketInfo[_ticketId].owner;
        idToTicketInfo[_ticketId].owner=payable(address(0));

        seller.transfer(ticketPrice);
        
        idToTicketInfo[_ticketId].owner=payable(msg.sender);
        tokenIdToAddress[_ticketId]=msg.sender;

        removeFromPool();
        

        emit TicketSoldThroughPool(_ticketId,msg.sender);

    }

    // Internal function to remove the sold ticket and shift others in the queue
    function removeFromPool()internal{

        for(uint i=0;i<ticketsInThePool.length-1;i++){
            ticketsInThePool[i]=ticketsInThePool[i+1];
        }
        ticketsInThePool.pop();
    }
      /////////////////////
     /// Get Functions////
    /////////////////////

    function getTier(uint256 tierNum) 
        public 
        pure 
        returns (Tier) 
    {

        if (tierNum == 0) {
            return Tier.Gold;
        } else if (tierNum == 1) {
            return Tier.Platinum;
        } else if (tierNum == 2) {
            return Tier.Diamond;
        } else {
            // Handle out-of-range input or return a default value
            revert("Invalid tier number");
        }
    }

    function getInitialTimeToEvent(uint256 _ticketId)
        public 
        view 
        returns(uint256)
    {
        return idToTicketInfo[_ticketId].initialtimeToEvent;
    }
    function getAddressMintedTo(uint256 _ticketId)
        public 
        view 
        returns(address)
    {
        return idToTicketInfo[_ticketId].owner;
    }
    function getTypeHash()public pure returns(bytes32){
        return SALE_TYPEHASH;
    }

    ////////

    /**
     * @dev Grants the minter role to a specified address.
     * @param account Address to be granted the role.
     */
    function grantMinterRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }
    
    /**
     * @dev Revokes the minter role from a specified address.
     * @param account Address from which the role needs to be revoked.
     */
    function revokeMinterRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl,ERC721,ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}