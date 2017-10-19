pragma solidity ^0.4.14;

import './InvestmentOffer.sol';
import './InvestmentAsset.sol';

contract SwapyExchange {

  // Protocol version
  string constant public VERSION = "1.0.0";

  event Offers(string _id, address _from, string _protocolVersion, address _offerAddress, uint256 _paybackMonths, uint256 _grossReturn, address[] _assets);


  // Creates a new investment offer
  function createOffer(string _id, uint256 _paybackMonths, uint256 _grossReturn, uint256[] _assets)
    returns(bool)
  {
    address newOffer = address(new InvestmentOffer(msg.sender, VERSION, _paybackMonths, _grossReturn));
    address[] memory newAssets = new address[](_assets.length);
    for (uint index = 0; index < _assets.length; index++) {
      newAssets[index] = address(new InvestmentAsset(msg.sender, VERSION, newOffer));
    }
    Offers(_id, msg.sender, VERSION, newOffer, _paybackMonths, _grossReturn, newAssets);
    return true;
  }

}
