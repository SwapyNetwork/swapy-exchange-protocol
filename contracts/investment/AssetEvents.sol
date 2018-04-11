pragma solidity ^0.4.21;

/**
 * @title Asset Events 
 * @dev Defines events fired by fundraising assets
 */
contract AssetEvents {

    /**
     * Events   
     */
    event LogInvested(address _owner, address _investor, uint256 _value);
    event LogCanceled(address _owner, address _investor, uint256 _value);
    event LogWithdrawal(address _owner, address _investor, uint256 _value);
    event LogRefused(address _owner, address _investor, uint256 _value);
    event LogReturned(address _owner, address _investor, uint256 _value, bool _delayed);
    event LogSupplied(address _owner, uint256 _amount, uint256 _assetFuel);
    event LogTokenWithdrawal(address _to, uint256 _amount);
    event LogForSale(address _investor, uint256 _value);
    event LogCanceledSell(address _investor, uint256 _value);
    
}    
