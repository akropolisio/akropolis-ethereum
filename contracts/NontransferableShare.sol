pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./utils/SafeDecimalMath.sol";

contract NontransferableShare is SafeDecimalMath {

    string public name;
    string public symbol;
    uint public totalSupply;
    mapping (address => uint) public balanceOf;

    constructor(string _name, string _symbol)
        public
    {
        name = _name;
        symbol = _symbol;
    }

    function createShares(address account, uint quantity) 
        internal
    {
        balanceOf[account] = safeAdd(balanceOf[account], quantity);
        totalSupply = safeAdd(totalSupply, quantity);
        emit CreatedShares(account, quantity);
        emit Transfer(address(0), account, quantity);
    }

    function destroyShares(address account, uint quantity) 
        internal
    {
        // safeSub() handles insufficient balance.
        balanceOf[account] = safeSub(balanceOf[account], quantity);
        totalSupply = safeSub(totalSupply, quantity);
        emit DestroyedShares(account, quantity);
        emit Transfer(account, address(0), quantity);
    }

    function transfer(address from, address to, uint quantity)
        internal
    {
        // safeSub() handles insufficient balance.
        balanceOf[from] = safeSub(balanceOf[from], quantity);
        balanceOf[to] = safeAdd(balanceOf[to], quantity);
        emit Transfer(from, to, quantity);
    }


    event CreatedShares(address indexed account, uint quantity);
    event DestroyedShares(address indexed account, uint quantity);
    event Transfer(address indexed from, address indexed to, uint quantity);

}