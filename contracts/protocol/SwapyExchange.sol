pragma solidity ^0.4.15;

import './InvestmentOffer.sol';
import './InvestmentAsset.sol';

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
      uint256 _paybackMonths,
      uint256 _grossReturn,
      string _currency,
      uint256 _fixedValue,
      bytes _offerTermsHash,
      uint256[] _assets)
    public
    returns(bool)
  {
    address newOffer = address(new InvestmentOffer(msg.sender, VERSION, _paybackMonths, _grossReturn, _currency, _fixedValue, _offerTermsHash));
    address[] memory newAssets = createOfferAssets(_assets,newOffer,_currency,_offerTermsHash);
    Offers(_id, msg.sender, VERSION, newOffer, newAssets);
    return true;
  }

  function createOfferAssets(
      uint256[] _assets,
      address _offerAddress,
      string _currency,
      bytes _offerTermsHash)
    internal  
    returns (address[])
  {
    address[] memory newAssets = new address[](_assets.length);
    for (uint index = 0; index < _assets.length; index++) {
      newAssets[index] = address(new InvestmentAsset(msg.sender, VERSION, _offerAddress, _currency, _assets[index], _offerTermsHash));
    }
    return newAssets;
  }  

}
