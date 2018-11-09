/*
* The MIT License
*
* Copyright (c) 2017-2018 , Akropolis Decentralised Ltd (Gibraltar), http://akropolis.io
*
*/

pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function approve(address spender, uint quantity) public returns (bool);
    function transfer(address to, uint quantity) public returns (bool);
    function transferFrom(address from, address to, uint quantity) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint quantity);
    event Approval(address indexed owner, address indexed spender, uint quantity);
}