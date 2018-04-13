pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestSwapyExchange {
    
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    SwapyExchange throwableProtocol = SwapyExchange(address(throwProxy));
    uint256[] _assetValues;

    // Testing the createOffer() function
    function testUserCanCreateOffer() public {
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        bool result = protocol.createOffer(
            uint256(360),
            uint256(10),
            bytes5("USD"),
            _assetValues
        );
        Assert.equal(result, true, "Assets must be created");
    }
    
}