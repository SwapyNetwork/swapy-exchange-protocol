pragma solidity ^0.4.17;

import "truffle/Assert.sol";

// Proxy contract for testing throws
contract ThrowProxy {
    address public target;
    bytes data;
    uint256 value;

    constructor(address _target) public {
        target = _target;
    }

    //prime the data using the fallback function.
    function() public payable {
        data = msg.data;
        if(msg.value > 0){
            value = msg.value;
        }
    }

    function execute() public returns (bool) {
        if(value > 0){
            return target.call.value(value)(data);
        }else {
            return target.call(data);
        }
    }

    function shouldThrow() public {
        bool r = this.execute.gas(200000)();
        Assert.isFalse(r, "Should throw an exception");
    }
}