pragma solidity ^0.4.4;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './InvestmentAsset.sol';

// Defines a fund raising contract 

contract InvestmentOffer {

  using SafeMath for uint256;

  // period to return the investment   
  uint256 public paybackMonths;
  // Gross return of investment 
  uint256 public grossReturn;
  // fixed currency symbol
  string public currency;
  // fixed fundraising value
  string public value;
  // Protocol version 
  string public protocolVersion;
  // Offer owner
  address public owner;

  event Assets(string _id, address _from, string _protocolVersion, address _assetAddress);

  function InvestmentOffer(address _owner, string _protocolVersion, uint256 _paybackMonths, uint256 _grossReturn, string _currency, uint256 _value) {
    owner = _owner;
    protocolVersion = _protocolVersion;
    paybackMonths = _paybackMonths;
    grossReturn = _grossReturn;
    currency = _currency;
    value = _value;
  }

  // Creates a new investment asset
  function createAsset(string _id) 
    onlyOwner 
    returns(bool) 
  {
    address newAsset = address(new InvestmentAsset(owner, protocolVersion, this));
    Assets(_id, owner, protocolVersion, newAsset);    
    return true;
  }

  // Checks if the owner is the caller
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
        
}