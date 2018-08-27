pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./interfaces/ERC20Token.sol";

contract Registry {

    struct Fund {
        string name; // You cannot modify the name after it is set
        address fundContract;
        uint32 risk;
        uint32 reputation;
    }

    // This will typically be the Akropolis Token
    ERC20Token public feeToken;
    // The fee cost to join this registry
    uint public fee;

    // Owner of the registry
    address public owner;

    // Index will always be 1 more than the actual index
    // Because of this these are not public, but there are public methods
    // that abstract the index away and go straight to the fund info
    mapping(string => uint) nameToIndex;
    mapping(address => uint) addressToIndex;
    Fund[] public funds;

    event NewFund(string indexed name, address indexed fund);
    event UpdatedFund(string indexed name, address indexed fund);


    modifier onlyOwner() {
        require(msg.sender == owner, "Sender must be owner");
        _;
    }

    constructor(ERC20Token _feeToken, uint _fee) public {
        owner = msg.sender;
        feeToken = _feeToken;
        fee = _fee;
    }

    function addFund(string name, uint32 risk, uint32 reputation) external {
        // Take the fee, contract must have paid allowance first
        require(feeToken.transferFrom(msg.sender, this, fee), "Failed to receive fee payment");
        // Ensure the fund isn't already listed here
        require(addressToIndex[msg.sender] == 0, "Fund already registered");
        require(nameToIndex[name] == 0, "Fund already registered");

        // Push the fund to the list
        funds.push(
            Fund(
                name,
                msg.sender,
                risk,
                reputation
            )
        );

        addressToIndex[msg.sender] = funds.length;
        nameToIndex[name] = funds.length;

        emit NewFund(name, msg.sender);
    }

    function modifyFund(uint32 risk, uint32 reputation) external {
        // require that the fund is already on the registry
        uint index = addressToIndex[msg.sender];
        require(index != 0, "Fund must be registered first");
        Fund storage f = funds[index - 1];
        f.risk = risk;
        f.reputation = reputation;

        emit UpdatedFund(f.name, msg.sender);
    }

    function transferFees(address to, uint quantity) external onlyOwner returns(bool) {
        return feeToken.transfer(to, quantity);
    }

    function addressToFund(address fund) external view returns(string, address, uint32, uint32) {
        uint index = addressToIndex[fund];
        require(index != 0, "Fund not found");
        Fund memory f = funds[index - 1];
        return (f.name, f.fundContract, f.risk, f.reputation);
    }

    function NameToFund(string name) external view returns(string, address, uint32, uint32) {
        uint index = nameToIndex[name];
        require(index != 0, "Fund not found");
        Fund memory f = funds[index - 1];
        return (f.name, f.fundContract, f.risk, f.reputation);
    }


}