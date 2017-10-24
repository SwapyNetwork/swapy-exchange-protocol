pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

// Defines a fund raising asset contract

contract InvestmentAsset {

    using SafeMath for uint256;

    // Reference to the investment offer
    address public offerAddress;
    // Asset owner
    address public owner;
    // Asset currency
    string public currency;
    // Asset fixed value
    uint256 public fixedValue;
    // Asset buyer
    address public investor;
    // Protocol version
    string public protocolVersion;
    // The hash of agreement terms
    bytes public agreementTermsHash;

    // possible stages of an asset
    enum Status { 
        AVAILABLE,
        PENDING_OWNER_AGREEMENT,
        INVESTED 
    }
    Status public status;

    event Transferred(
        string _id,
        address _from,
        address _to,
        uint256 _value
    );

    event Canceled(
        string _id,
        address _owner,
        address _investor,
        uint256 _value
    );

    event Agreements(
        string _id,
        address _owner,
        address _investor,
        uint256 _value,
        bytes _terms
    );

    event Disagreements(
        string _id,
        address _owner,
        address _investor,
        uint256 _value
    );

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

    // Checks if the investor is the caller
    modifier onlyInvestor() {
        require(msg.sender == investor);
        _;
    }

    function InvestmentAsset(address _owner, string _protocolVersion, address _offerAddress, string _currency, uint256 _fixedValue) {
        owner = _owner;
        protocolVersion = _protocolVersion;
        offerAddress = _offerAddress;
        currency = _currency;
        fixedValue = _fixedValue;
        status = Status.AVAILABLE;
    }

    function makeAvailable() 
        private
        returns(address, uint256) 
    {   
        uint256 investedValue = this.balance;
        investor.transfer(invested);
        address currentInvestor = investor;
        investor = address(0);
        status = Status.AVAILABLE;
        return (currentInvestor, investedValue);
    }

    // Add investment interest in this asset and retain the funds within the smart contract 
    function invest(string _id, bytes _agreementTermsHash) payable
         hasStatus(Status.AVAILABLE)
         returns(bool)
    {
        investor = msg.sender;
        agreementTermsHash = _agreementTermsHash;
        status = Status.PENDING_OWNER_AGREEMENT;
        Transferred(_id, investor, owner, this.balance);
        return true;
    }

    // Cancel the pending investment and refund the investor
    function cancelInvestment(string _id)
        onlyInvestor
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Canceled(_id, owner, currentInvestor, investedValue);
        return true;
    }    

    // Agree the investor as the asset buyer and withdraw funds
    function agreeInvestment(string _id, bytes _agreementTermsHash)
        onlyOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        returns(bool)
    {
        // compare the document signed by the offer owner and investor
        if (sha3(agreementTermsHash) == sha3(_agreementTermsHash)) {
            // @todo check how to transfer all the funds 
            owner.transfer();
            status = Status.INVESTED;
            Agreements(_id, owner, investor, agreementTermsHash);
            return true;
        }
    }

    // Disagree the pending investment and refund the investor
    function disagreeInvestment(string _id)
        onlyOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Disagreements(_id, owner, currentInvestor, investedValue);
        return true;
    }



}
