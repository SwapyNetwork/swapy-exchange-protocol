pragma solidity ^0.4.4;

import './InvestmentOffer.sol';

contract SwapyExchange {

  // Protocol version 
  string constant public VERSION = "1.0.0";  

  event Offers(address from, string protocolVersion, address offerAddress, uint256 paybackMonths, uint256 grossReturn);

  function createOffer(uint256 _paybackMonths, uint256 _grossReturn) 
    returns(bool) 
  {
    address newOffer = address(new InvestmentOffer(msg.sender, VERSION, _paybackMonths, _grossReturn));
    Offers(msg.sender, VERSION, newOffer, _paybackMonths, _grossReturn);    
    return true;
  }
        
}