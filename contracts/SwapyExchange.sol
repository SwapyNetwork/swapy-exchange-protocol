pragma solidity ^0.4.14;

import './investment/InvestmentOffer.sol';
import './investment/InvestmentAsset.sol';

contract SwapyExchange {

  // Protocol version
  string constant public VERSION = "1.0.0";

  event Offers(
    string _id,
    address _from,
    string _protocolVersion,
    address _offerAddress,
    address[] _assets
  );


  // Creates a new investment offer
  function createOffer(
      string _id,
      uint256 _paybackDays,
      uint256 _grossReturn,
      string _currency,
      uint256 _fixedValue,
      bytes _offerTermsHash,
      uint256[] _assets)
    public
    returns(bool)
  {
    address newOffer = address(new InvestmentOffer(msg.sender, VERSION, _paybackDays, _grossReturn, _currency, _fixedValue, _offerTermsHash));
    address[] memory newAssets = createOfferAssets(_assets,newOffer,_currency,_offerTermsHash, _paybackDays);
    Offers(_id, msg.sender, VERSION, newOffer, newAssets);
    return true;
  }

  function createOfferAssets(
      uint256[] _assets,
      address _offerAddress,
      string _currency,
      bytes _offerTermsHash,
      uint _paybackDays)
    internal  
    returns (address[])
  {
    address[] memory newAssets = new address[](_assets.length);
    for (uint index = 0; index < _assets.length; index++) {
      newAssets[index] = address(new InvestmentAsset(msg.sender, VERSION, _offerAddress, _currency, _assets[index], _offerTermsHash, _paybackDays));
    }
    return newAssets;
  }  

}
