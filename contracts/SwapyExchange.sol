pragma solidity ^0.4.18;

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

  event ForSale(
    address _investor,
    address _asset,
    uint256 _value
  );

  event Bought(
    address _buyer,
    address _asset,
    uint256 _value
  );

  function SwapyExchange(address _assetLibrary, address _token)
    public
  {
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
        this,
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
    public
    returns(bool)
  {
    uint256 assetValue = msg.value / _assets.length;
    for (uint index = 0; index < _assets.length; index++) {
      require(_assets[index].call.value(assetValue)(bytes4(keccak256("invest(address)")), msg.sender));
    }
    Investments(msg.sender, _assets, msg.value);
    return true;
  }

  function sellAsset(address _asset, uint256 _value)
    public
    returns(bool)
  {
    InvestmentAsset asset = InvestmentAsset(_asset);
    //require(msg.sender == asset.investor());
    require(_asset.call(bytes4(keccak256("sell(uint256)")), _value));
    ForSale(msg.sender, _asset, _value);
    return true;
  }

  function buyAsset(address _asset) payable
    public
    returns(bool)
  {
    uint256 assetValue = msg.value;
    require(_asset.call.value(assetValue)(bytes4(keccak256("buy(address)")), msg.sender));
    Bought(msg.sender, _asset, msg.value);
    return true;
  }

}
