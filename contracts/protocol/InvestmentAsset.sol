pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

// Defines a fund raising asset contract

contract InvestmentAsset {

    using SafeMath for uint256;

    // Reference to the investment offer
    address public offerAddress;
    // Asset owner
    address public owner;
    // Asset buyer
    address public investor;
    // Asset value
    uint256 public value;
    // Protocol version
    string public protocolVersion;
    // The hash of agreement terms
    bytes public agreementTermsHash;

    // possible stages of an asset
    enum Status { Open, Agreed, Invested }
    Status public status;

    event Transferred(string _id, address _from, address _to, uint256 _value);

    event Agreements(string _id, address _owner, address _investor, uint256 _value, bytes _terms);

    function InvestmentAsset(address _owner, string _protocolVersion, address _offerAddress) {
        owner = _owner;
        protocolVersion = _protocolVersion;
        offerAddress = _offerAddress;
        status = Status.Open;
    }

    // Transfer funds from investor to the offer owner
    function transferFunds(string _id, bytes _agreementTermsHash) payable
         onlyInvestor
         hasStatus(Status.Agreed)
         isValidValue(value)
         returns(bool)
    {
        // compare the document signed by the offer owner and investor
        if (sha3(agreementTermsHash) == sha3(_agreementTermsHash)) {
            owner.transfer(msg.value);
            status = Status.Invested;
            Transferred(_id, investor, owner, msg.value);
            return true;
        }
    }

    // Agrees an investor as the asset buyer and sets the contract terms and value
    function agreeInvestment(string _id, address _investor, bytes _agreementTermsHash, uint256 _value)
        onlyOwner
        hasStatus(Status.Open)
        returns(bool)
    {
        investor = _investor;
        agreementTermsHash = _agreementTermsHash;
        value = _value * 1 wei;
        status = Status.Agreed;
        Agreements(_id, owner, investor, value, agreementTermsHash);
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
