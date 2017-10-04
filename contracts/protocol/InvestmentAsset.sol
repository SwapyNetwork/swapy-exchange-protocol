pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

// Defines a fund raising asset contract 

contract InvestmentAsset {

    using SafeMath for uint256;
    
    // Reference to the investment offer
    address offerAddress;
    // Asset owner
    address owner; 
    // Asset buyer
    address investor;
    // Asset value
    uint256 value;
    // Protocol version
    string protocolVersion;
    // The hash of agreement terms 
    bytes agreementTermsHash;
    
    // possible stages of an asset
    enum Status { Open, Agreed, Invested }
    Status public status;
    
    event Transferred(address from, address to, uint256 value);
    event Agreements(address owner, address investor, uint256 value, bytes terms);

    function InvestmentAsset(address _owner, string _protocolVersion) {   
        owner = _owner;
        protocolVersion = _protocolVersion;
        // the message sender is the investment offer contract 
        offerAddress = msg.sender;    
        status = Status.Open;
    }   
    
    // Transfer funds from investor to the offer owner
    function transferFunds(bytes _agreementTermsHash) payable
         onlyInvestor
         hasStatus(Status.Agreed) 
         isValidValue(value)
         returns(bool)
    {
        // compare the document signed by the offer owner and investor
        if (sha3(agreementTermsHash) == sha3(_agreementTermsHash)) {
            owner.transfer(msg.value);
            status = Status.Invested;
            Transferred(investor, owner, msg.value);
            return true;
        }
    }
    
    // Agrees an investor as the asset buyer and sets the contract terms and value
    function agreeInvestment(address _investor, bytes _agreementTermsHash, uint256 _value)  
        onlyOwner
        hasStatus(Status.Open)
        returns(bool)
    {
        investor = _investor;
        agreementTermsHash = _agreementTermsHash;
        value = _value;
        status = Status.Agreed;
        Agreements(owner, investor, value, agreementTermsHash);   
        return true;
    }

    // Checks the current asset's status
    modifier hasStatus(Status _status) {
        require(status == _status);
        _;
    }
    
    // Checks if the owner is the caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
    // Checks if the current investor is the caller 
    modifier onlyInvestor() {
        require(msg.sender == investor);
        _;
    }

    // Checks if the value was sent according to specified
    modifier isValidValue(uint256 _value) {
        require(msg.value != 0 && msg.value == _value);
        _;    
    }

}