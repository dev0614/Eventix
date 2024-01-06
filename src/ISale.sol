//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

interface ISale{
    struct Sale{
        address seller;
        address buyer;
        uint256 ticketId;
        uint256 price;
    }
}