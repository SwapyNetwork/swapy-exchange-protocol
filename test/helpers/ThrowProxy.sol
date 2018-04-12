pragma solidity ^0.4.17;

import "truffle/Assert.sol";

// Proxy contract for testing throws
contract ThrowProxy {
    address public target;
    bytes data;

    function ThrowProxy(address _target) public {
        target = _target;
    }

    //prime the data using the fallback function.
    function() public {
        data = msg.data;
    }

    function execute() public returns (bool) {
        return target.call(data);
    }

    function shouldThrow() public {
        bool r = this.execute.gas(200000)();
        Assert.isFalse(r, "Should throw an exception");
    }
}