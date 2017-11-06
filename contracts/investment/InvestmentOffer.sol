pragma solidity ^0.4.15;

import './InvestmentAsset.sol';

// Defines a fund raising contract 

contract InvestmentOffer {

  // period to return the investment   
  uint256 public paybackMonths;
  // Gross return of investment 
  uint256 public grossReturn;
  // fixed currency symbol
  string public currency;
  // fixed fundraising value
  uint256 public fixedValue;
  // Protocol version 
  string public protocolVersion;
  // Offer owner
  address public owner;
  // Contractual terms hash of investment
  bytes public offerTermsHash;

  event Assets(
    string _id,
    address _from,
    string _protocolVersion,
    address _assetAddress,
    string _currency,
    uint256 _fixedValue,
    bytes _assetTermsHash
  );
  
  // Checks if the owner is the caller
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function InvestmentOffer(
    address _owner,
    string _protocolVersion,
    uint256 _paybackMonths,
    uint256 _grossReturn,
    string _currency,
    uint256 _fixedValue,
    bytes _offerTermsHash)
    public
  {
    owner = _owner;
    protocolVersion = _protocolVersion;
    paybackMonths = _paybackMonths;
    grossReturn = _grossReturn;
    currency = _currency;
    fixedValue = _fixedValue;
    offerTermsHash = _offerTermsHash;
  }

  // Creates a new investment asset
  function createAsset(string _id, uint256 _fixedValue) 
    onlyOwner 
    public
    returns(bool) 
  {
    address newAsset = address(new InvestmentAsset(owner, protocolVersion, this, currency, _fixedValue, offerTermsHash));
    Assets(_id, owner, protocolVersion, newAsset, currency, _fixedValue, offerTermsHash);    
    return true;
  }

}