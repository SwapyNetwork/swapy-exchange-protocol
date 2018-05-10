pragma solidity ^0.4.23;

contract PaymentResolver {
    
    address public owner; 
    
    mapping(address => bytes8) tokenStandard;
    mapping(bytes8 => mapping(bytes8 => address)) standardGateway;

    constructor() {
        owner = msg.sender;
    }
    
}