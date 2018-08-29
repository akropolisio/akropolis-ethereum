pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

contract Ownable {
    address owner;

    event NewOwner(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit NewOwner(newOwner);
    }
}