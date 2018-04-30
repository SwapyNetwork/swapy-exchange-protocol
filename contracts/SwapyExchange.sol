pragma solidity ^0.4.23;

import "./investment/InvestmentAsset.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

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
    bytes8 public latestVersion;
    
    /**
     * Storage
     */
    mapping(bytes8 => address) libraries;
    address public owner;
    address public token;
    
    /**
     * Events   
     */
    event LogOffers(address indexed _from, bytes8 _protocolVersion, address[] _assets);
    event LogInvestments(address indexed _investor, address[] _assets, uint256 _value);
    event LogForSale(address indexed _investor, address _asset, uint256 _value);
    event LogBought(address indexed _buyer, address _asset, uint256 _value);
    event LogVersioning(bytes8 _version, address _library);

    /**
     * Modifiers   
     */
    modifier notEmpty(address[] _assets){
        require(_assets.length > 0, "Empty list of assets");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /**
     * @param _token Address of Swapy Token
     */   
    constructor(address _token, bytes8 _version, address _library)
        public
    {
        token = _token;
        owner = msg.sender;
        setLibrary(_version, _library);
    }

    /**
     * @dev add a new protocol library - internal
     * @param _version Version
     * @param _library Library's address.
     */
    function setLibrary(
        bytes8 _version,
        address _library)
        private
    {
        require(_version != bytes8(0), "Invalid version");
        require(_library != address(0), "Invalid library address");
        require(libraries[_version] == address(0), "Library version already added");
        latestVersion = _version;
        libraries[_version] = _library;
        emit LogVersioning(_version, _library);
    }

    /**
     * @dev retrieve library address of a version
     * @param _version Version
     * @return Address of library
     */
    function getLibrary(bytes8 _version) view public returns(address) {
        require(libraries[_version] != address(0));
        return libraries[_version];
    }
    /**
     * @dev add a new protocol library
     * @param _version Version
     * @param _library Library's address.
     * @return Success
     */ 
    function addLibrary(
        bytes8 _version,
        address _library)
        onlyOwner
        external
        returns(bool)
    {
        setLibrary(_version, _library);
        return true;
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
        bytes8 _version,
        uint256 _paybackDays,
        uint256 _grossReturn,
        bytes5 _currency,
        uint256[] _assets)
        external
        returns(address[] newAssets)
    {
        bytes8 version = _version == bytes8(0) ? latestVersion : _version;
        require(libraries[version] != address(0), "Library version doesn't exists");
        newAssets = createOfferAssets(_assets, _currency, _paybackDays, _grossReturn, version);
        emit LogOffers(msg.sender, _version, newAssets);
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
        uint _grossReturn,
        bytes8 _version)
        internal
        returns (address[])
    {
        address[] memory newAssets = new address[](_assets.length);
        for (uint index = 0; index < _assets.length; index++) {
            newAssets[index] = new InvestmentAsset(
                libraries[_version],
                this,
                msg.sender,
                _version,
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
            require(address(asset).call.value(value)(abi.encodeWithSignature("invest(address)",address(msg.sender))), "An error ocurred when investing");
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
            require(address(asset).call(abi.encodeWithSignature("withdrawFunds()")), "An error ocurred when withdrawing asset's funds");
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
            require(address(asset).call(abi.encodeWithSignature("refuseInvestment()")), "An error ocurred when refusing investment");
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
            require(address(asset).call(abi.encodeWithSignature("cancelInvestment()")), "An error ocurred when canceling investment");
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
        require(_assets.length == _values.length, "All the assets should have a value on sale");
        for(uint index = 0; index < _assets.length; index++){
            InvestmentAsset asset = InvestmentAsset(_assets[index]);
            require(msg.sender == asset.investor(), "The user isn't asset's investor");
            require(address(asset).call(abi.encodeWithSignature("sell(uint256)",_values[index])), "An error ocurred when puting the asset on sale");
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
            require(address(asset).call(abi.encodeWithSignature("cancelSellOrder()")), "An error ocurred when removing the asset from market place");
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
        require(address(asset).call.value(assetValue)(abi.encodeWithSignature("buy(address)",msg.sender)), "An error ocurred when buying the asset");
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
            require(address(asset).call(abi.encodeWithSignature("acceptSale()")), "An error ocurred when accepting sale");
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
            require(address(asset).call(abi.encodeWithSignature("refuseSale()")), "An error ocurred when refusing sale");
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
            require(address(asset).call(abi.encodeWithSignature("cancelSale()")), "An error ocurred when canceling sale");
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
            require(address(asset).call(abi.encodeWithSignature("requireTokenFuel()")), "An error ocurred when requiring asset's collateral");
        }
        return true;
    }

}
