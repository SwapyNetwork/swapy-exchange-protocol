pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestSwapyExchange {
    
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    SwapyExchange throwableProtocol = SwapyExchange(address(throwProxy));
    
    // Testing the createOffer() function
    function testUserCreateOffer() public {
        uint256[] memory _assets;
        _assets[0] = uint256(500);
        _assets[1] = uint256(500);
        _assets[2] = uint256(500);
        bool result = protocol.createOffer(
            uint256(360),
            uint256(10),
            "USD",
            _assets
        );
        Assert.equal(result, true, "Five assets must be created");
    }
    
}