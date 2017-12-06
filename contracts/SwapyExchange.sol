pragma solidity ^0.4.15;

import './investment/InvestmentAsset.sol';

contract SwapyExchange {

  // Protocol version
  string constant public VERSION = "1.0.0";
  address public assetLibrary;
  address public token;

  event Offers(
    address _from,
    string _protocolVersion,
    address[] _assets
  );

  event Investments(
    address _investor,
    address[] _assets,
    uint256 _value
  );

  function SwapyExchange(address _assetLibrary, address _token) {
    assetLibrary = _assetLibrary;
    token = _token;
  }

  // Creates a new investment offer
  function createOffer(
      uint256 _paybackDays,
      uint256 _grossReturn,
      string _currency,
      bytes _offerTermsHash,
      uint256[] _assets)
    public
    returns(bool)
  {
    address[] memory newAssets = createOfferAssets(_assets, _currency, _offerTermsHash, _paybackDays, _grossReturn);
    Offers(msg.sender, VERSION, newAssets);
    return true;
  }

  function createOfferAssets(
      uint256[] _assets,
      string _currency,
      bytes _offerTermsHash,
      uint _paybackDays,
      uint _grossReturn)
    internal
    returns (address[])
  {
    address[] memory newAssets = new address[](_assets.length);
    for (uint index = 0; index < _assets.length; index++) {
      newAssets[index] = new InvestmentAsset(
        assetLibrary,
        msg.sender,
        VERSION,
        _currency,
        _assets[index],
        _offerTermsHash,
        _paybackDays,
        _grossReturn,
        token
      );
    }
    return newAssets;
  }

  function invest(address[] _assets) payable
    returns(bool)
  {
    uint256 assetValue = msg.value / _assets.length;
    for (uint index = 0; index < _assets.length; index++) {
      require(_assets[index].call.value(assetValue)(bytes4(sha3("invest(address)")), msg.sender));
    }
    Investments(msg.sender, _assets, msg.value);
    return true;
  }

  function sell(address[] _assets) 
    returns(bool)
  {
    return true;
  }

}
