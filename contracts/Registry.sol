pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Owned.sol";

contract Registry is Owned {
    using IterableSet for IterableSet.Set;

    // This will typically be the Akropolis Token
    ERC20Token public feeToken;

    // The fee cost to join this registry
    uint public joiningFee;

    // Iterable set of funds
    IterableSet.Set Funds;

    // List the funds a user is in
    mapping(address => address[]) public userToFund;

    event NewFund(address indexed fund);
    event RemovedFund(address indexed fund);

    constructor(ERC20Token _feeToken, uint _fee)
        Owned(msg.sender)
        public 
    {
        feeToken = _feeToken;
        joiningFee = _fee;
        Funds.initialise();
    }

    function addFund()
        external 
        returns(bool)
    {
        // This function is called by the fund itself!
        // Take the fee, contract must have paid allowance first
        require(
            feeToken.transferFrom(msg.sender, this, joiningFee),
            "Failed to receive fee payment"
        );
        // Ensure the fund isn't already listed here
        require(!Funds.contains(msg.sender), "Fund already registered");
        // Add the fund to the set
        Funds.add(msg.sender);
        // Emit an event for successfully adding a new fund
        emit NewFund(msg.sender);
        // Return true if the above didn't revert
        return true;
    }

    function removeFund()
        external
    {
        // Ensure the fund is listed here
        require(Funds.contains(msg.sender), "Fund not registered");
        Funds.remove(msg.sender);
        emit RemovedFund(msg.sender);
    }

    function transferFees(address to, uint quantity)
        external
        onlyOwner
        returns(bool)
    {
        // Called by the Registry owner to transfer the fee token fees out!
        return feeToken.transfer(to, quantity);
    }

    function addUser(address fund)
        external
    {
        // The user adds itself to the registry
        require(Funds.contains(fund), "Fund is not in registry");
        userToFund[msg.sender].push(fund);
    }

    function fundSize()
        external 
        view 
        returns(uint)
    {
        // Returns the size of the funds, so we can iterate over the list of funds!
        return Funds.size();
    }

    function fundAt(uint index) 
        external 
        view 
        returns(address)
    {
        return Funds.get(index);
    }
}