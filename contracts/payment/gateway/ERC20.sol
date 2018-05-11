pragma solidity ^0.4.23;

import { StandardToken as Token } from "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract ERC20 {

    function balanceOf(address tokenAddr, address wallet) returns(uint256) { 
        Token token = Token(tokenAddr);
        return token.balanceOf(wallet);
    }

}