pragma solidity ^0.4.15;

import './AssetEvents.sol';

// Defines a fund raising asset contract

contract InvestmentAsset is AssetEvents {

    address public assetLibrary;
    
    function InvestmentAsset(address _library) {
        assetLibrary = _library;
    }

    function () {
        assetLibrary.delegatecall(msg.data);
    }
}