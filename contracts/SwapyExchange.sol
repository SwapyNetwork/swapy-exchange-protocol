pragma solidity ^0.4.23;

import "./investment/InvestmentAsset.sol";
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
    event LogOffers(address indexed _from, bytes8 _protocolVersion, address[] _assets);
    event LogInvestments(address indexed _investor, address[] _assets, uint256 _value);
    event LogForSale(address indexed _investor, address _asset, uint256 _value);
    event LogBought(address indexed _buyer, address _asset, uint256 _value);

    /**
     * Modifiers   
     */
    modifier notEmpty(address[] _assets){
        require(_assets.length > 0, "Empty list of assets");
        _;
    }

    /**
     * @param _assetLibrary Address of library that contains asset's logic
     * @param _token Address of Swapy Token
     */   
    constructor(address _assetLibrary, address _token)
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
        returns(address[] newAssets)
    {
        newAssets = createOfferAssets(_assets, _currency, _paybackDays, _grossReturn);
        emit LogOffers(msg.sender, VERSION, newAssets);
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
        require(
            (value.mul(_assets.length) == msg.value) && value > 0,
            "The value transfered doesn't match with the unit value times the number of assets"
        );
        for (uint index = 0; index < _assets.length; index++) {
            InvestmentAsset asset = InvestmentAsset(_assets[index]);  
            require(address(asset).call.value(value)(abi.encodeWithSignature("invest(address)",address(msg.sender))), "An error ocured when investing");
        }
        emit LogInvestments(msg.sender, _assets, msg.value);
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.owner(), "The user isn't asset's owner");
            require(address(asset).call(abi.encodeWithSignature("withdrawFunds()")), "An error ocured when withdrawing asset's funds");
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.owner(), "The user isn't asset's owner");
            require(address(asset).call(abi.encodeWithSignature("refuseInvestment()")), "An error ocured when refusing investment");
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("cancelInvestment()")), "An error ocured when canceling investment");
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("sell(uint256)",_values[index])), "An error ocured when puting the asset on sale");
            emit LogForSale(msg.sender, _assets[index], _values[index]);
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("cancelSellOrder()")), "An error ocured when removing the asset from market place");
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
        InvestmentAsset asset = InvestmentAsset(_asset);
        require(address(asset).call.value(assetValue)(abi.encodeWithSignature("buy(address)",msg.sender)), "An error ocured when buying the asset");
        emit LogBought(msg.sender, _asset, msg.value);
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("acceptSale()")), "An error ocured when accepting sale");
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("refuseSale()")), "An error ocured when refusing sale");
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            address buyer;
            (,buyer) = asset.sellData();
            require(msg.sender == buyer, "The user isn't asset's buyer");
            require(address(asset).call(abi.encodeWithSignature("cancelSale()")), "An error ocured when canceling sale");
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
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("requireTokenFuel()")), "An ocured when requiring asset's collateral");
        }
        return true;
    }

}
