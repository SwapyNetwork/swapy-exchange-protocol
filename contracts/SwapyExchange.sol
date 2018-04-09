pragma solidity ^0.4.18;

import "./investment/InvestmentAsset.sol";
import "./investment/AssetLibrary.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Swapy Exchange Protocol 
 * @dev Allows the creation of fundraising offers and many actions with them
 */
contract SwapyExchange {
    /**
     * Add safety checks for uint operations
     */
    using SafeMath for uint256;
    
    /**
     * Constants
     */
    bytes8 constant public VERSION = "1.0.0";
    
    /**
     * Storage
     */
    address public assetLibrary;
    address public token;
    
    /**
     * Events   
     */
    event Offers(address indexed _from, bytes8 _protocolVersion, address[] _assets);
    event Investments(address indexed _investor, address[] _assets, uint256 _value);
    event ForSale(address indexed _investor, address _asset, uint256 _value);
    event Bought(address indexed _buyer, address _asset, uint256 _value);

    /**
     * Modifiers   
     */
    modifier notEmpty(address[] _assets){
        require(_assets.length > 0);
        _;
    }

    /**
     * @param _assetLibrary Address of library that contains asset's logic
     * @param _token Address of Swapy Token
     */   
    function SwapyExchange(address _assetLibrary, address _token)
        public
    {
        assetLibrary = _assetLibrary;
        token = _token;
    }

    /**
     * @dev create a fundraising offer
     * @param _paybackDays Period in days until the return of investment
     * @param _grossReturn Gross return on investment
     * @param _currency Fundraising base currency, i.e, USD
     * @param _assets Asset's values.
     * @return Success
     */ 
    function createOffer(
        uint256 _paybackDays,
        uint256 _grossReturn,
        bytes5 _currency,
        uint256[] _assets)
        external
        returns(bool)
    {
        address[] memory newAssets = createOfferAssets(_assets, _currency, _paybackDays, _grossReturn);
        Offers(msg.sender, VERSION, newAssets);
        return true;
    }

    /**
     * @dev Create fundraising assets
     * @param _assets Asset's values. The length will determine the number of assets composes the fundraising
     * @param _currency Fundraising base currency, i.e, USD
     * @param _paybackDays Period in days until the return of investment
     * @param _grossReturn Gross return on investment
     * @return Address of assets created
     */ 
    function createOfferAssets(
        uint256[] _assets,
        bytes5 _currency,
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
    /**
     * @dev Invest in fundraising assets
     * @param _assets Asset addresses
     * @param value Asset unit value, i.e, _assets.length = 5 and msg.value = 5 ETH, then _value must be equal 1 ETH
     * @return Success
     */ 
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

    /**
     * @dev Withdraw investments
     * @param _assets Asset addresses
     * @return Success
     */ 
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
    
    /**
     * @dev Refuse investments
     * @param _assets Asset addresses
     * @return Success
     */ 
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

    /**
     * @dev Cancel investments made
     * @param _assets Asset addresses
     * @return Success
     */ 
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

    /**
     * @dev Put invested assets for sale.
     * @param _assets Asset addresses
     * @param _values Sale values. _assets[0] => _values[0], ..., _assets[n] => _values[n]
     * @return Success
     */ 
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
    
    /**
     * @dev Remove available assets from market place
     * @param _assets Asset addresses
     * @return Success
     */ 
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

    /**
     * @dev Buy an available asset on market place
     * @param _asset Asset address
     * @return Success
     */
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
    
    /**
     * @dev Accept purchases on market place
     * @param _assets Asset addresses
     * @return Success
     */
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
    
    /**
     * @dev Refuse purchases on market place
     * @param _assets Asset addresses
     * @return Success
     */
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

    /**
     * @dev Cancel purchases made
     * @param _assets Asset addresses
     * @return Success
     */
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
    
    /**
     * @dev Require collateral of investments made
     * @param _assets Asset addresses
     * @return Success
     */
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
