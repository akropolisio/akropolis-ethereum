pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "../NontransferableShare.sol";

contract PublicNontransferableShare is NontransferableShare {

    constructor(string _name, string _symbol) 
        NontransferableShare(_name, _symbol)
        public
    {}

    function createShares(address account, uint quantity)
        public
    {
        _createShares(account, quantity);
    }

    function destroyShares(address account, uint quantity)
        public
    {
        _destroyShares(account, quantity);
    }

    function transfer(address from, address to, uint quantity)
        public
    {
        _transfer(from, to, quantity);
    }
}
