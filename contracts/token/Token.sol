pragma solidity ^0.4.15;

import "zeppelin-solidity/contracts/token/StandardToken.sol";

contract Token is StandardToken {
    
    string public constant name = "SwapyBeta";
    string public constant symbol = "SWBETA";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 10000000000000;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
    */
    function Token() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;  
    }
} 