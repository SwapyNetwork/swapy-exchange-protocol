pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestSwapyExchange {
    
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    SwapyExchange throwableProtocol = SwapyExchange(address(throwProxy));
    uint256[] _assetValues;
    address[] assets;

    // Testing the createOffer() function
    function testUserCanCreateOffer() public {
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        assets = protocol.createOffer(
            uint256(360),
            uint256(10),
            bytes5("USD"),
            _assetValues
        );
        Assert.equal(assets.length, 3, "3 Assets must be created");
    }
    
}