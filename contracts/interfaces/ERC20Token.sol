pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

contract ERC20Token {
    string public constant name = "Token Name";
    string public constant symbol = "SYM";
    uint8 public constant decimals = 18;

    function totalSupply() public view returns (uint);
    function balanceOf(address user) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address spender, uint quantity) public returns (bool);
    function transfer(address to, uint quantity) public returns (bool);
    function transferFrom(address from, address to, uint quantity) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint quantity);
    event Approval(address indexed owner, address indexed spender, uint quantity);
}