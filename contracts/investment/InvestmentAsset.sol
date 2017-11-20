pragma solidity ^0.4.15;


// Defines a fund raising asset contract

contract InvestmentAsset {

    address public assetLibrary;
    
    // Reference to the investment offer
    address public offerAddress;
    // Asset owner
    address public owner;
    // Asset currency
    string public currency;
    // Asset fixed value
    uint256 public fixedValue;
    // period to return the investment
    uint256 public paybackDays;
    // Gross return of investment
    uint256 public grossReturn;
    // Asset buyer
    address public investor;
    // Protocol version
    string public protocolVersion;
    // Contractual terms hash of investment
    bytes public assetTermsHash;
    // Document hash agreeing the contractual terms
    bytes public agreementHash;
    // investment timestamp
    uint public investedAt;

    // possible stages of an asset
    enum Status {
        AVAILABLE,
        PENDING_OWNER_AGREEMENT,
        INVESTED,
        RETURNED,
        DELAYED_RETURN
    }
    Status public status;

    function InvestmentAsset(address _library)
    {
        assetLibrary = _library;
    }

    function () 
       public 
    {
        assetLibrary.delegatecall(msg.data);
    }

}
