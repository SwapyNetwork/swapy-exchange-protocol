pragma solidity ^0.4.18;

import "./investment/InvestmentAsset.sol";
import "./investment/AssetLibrary.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract SwapyExchange {
    using SafeMath for uint256;
    
    // Protocol version
    string constant public VERSION = "1.0.0";
    address public assetLibrary;
    address public token;
    
    event Offers(
        address indexed _from,
        string _protocolVersion,
        address[] _assets
    );

    event Investments(
        address indexed _investor,
        address[] _assets,
        uint256 _value
    );

    event ForSale(
        address indexed _investor,
        address _asset,
        uint256 _value
    );

    event Bought(
        address indexed _buyer,
        address _asset,
        uint256 _value
    );

    modifier notEmpty(address[] _assets){
        require(_assets.length > 0);
        _;
    }

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
        uint256[] _assets)
        external
        returns(bool)
    {
        address[] memory newAssets = createOfferAssets(_assets, _currency, _paybackDays, _grossReturn);
        Offers(msg.sender, VERSION, newAssets);
        return true;
    }

    function createOfferAssets(
        uint256[] _assets,
        string _currency,
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
                _paybackDays,
                _grossReturn,
                token
            );
        }
        return newAssets;
    }

    function invest(address[] _assets, uint256 value) payable
        notEmpty(_assets)
        external
        returns(bool)
    {
        require((value.mul(_assets.length) == msg.value) && value > 0);
        for (uint index = 0; index < _assets.length; index++) {
            AssetLibrary asset = AssetLibrary(_assets[index]);  
            require(asset.invest.value(value)(msg.sender));
        }
        Investments(msg.sender, _assets, msg.value);
        return true;
    }

    function withdrawFunds(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++){
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.owner());
            require(asset.withdrawFunds());
        }
        return true;
    }
    
    function refuseInvestment(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++){
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.owner());
            require(asset.refuseInvestment());
        }
        return true;
    }

    function cancelInvestment(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++){
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.investor());
            require(asset.cancelInvestment());
        }
        return true;
    }

    function sellAssets(address[] _assets, uint256[] _values)
        notEmpty(_assets)
        external
        returns(bool)
    {
        require(_assets.length == _values.length);
        for(uint index = 0; index < _assets.length; index++){
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.investor());
            require(asset.sell(_values[index]));
            ForSale(msg.sender, _assets[index], _values[index]);
        }
        return true;
    }
    
    function cancelSellOrder(address[] _assets)
        notEmpty(_assets) 
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++){
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.investor());
            require(asset.cancelSellOrder());
        }
        return true;
    }

    function buyAsset(address _asset) payable
        external
        returns(bool)
    {
        uint256 assetValue = msg.value;
        AssetLibrary asset = AssetLibrary(_asset);
        require(asset.buy.value(assetValue)(msg.sender));
        Bought(msg.sender, _asset, msg.value);
        return true;
    }
    
    function acceptSale(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++) {
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.investor());
            require(asset.acceptSale());
        }
        return true;
    }
    
    function refuseSale(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++) {
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.investor());
            require(asset.refuseSale());
        }
        return true;
    }

    function cancelSale(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++) {
            AssetLibrary asset = AssetLibrary(_assets[index]);
            var (,buyer) = asset.sellData();
            require(msg.sender == buyer);
            require(asset.cancelSale());
        }
        return true;
    }
    
    function requireTokenFuel(address[] _assets) 
        notEmpty(_assets)
        external
        returns(bool)
    {
        for(uint index = 0; index < _assets.length; index++) {
            AssetLibrary asset = AssetLibrary(_assets[index]);
            require(msg.sender == asset.investor());
            require(asset.requireTokenFuel());
        }
        return true;
    }

}
