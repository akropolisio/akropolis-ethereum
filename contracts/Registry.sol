pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./AkropolisFund.sol";
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
    mapping(address => AkropolisFund[]) public userToFunds;

    event NewFund(AkropolisFund indexed fund);
    event RemovedFund(AkropolisFund indexed fund);
    event NewFee(uint indexed newFee);
    event NewFeeToken(ERC20Token indexed newFeeToken);

    constructor(ERC20Token _feeToken, uint _fee)
        Owned(msg.sender)
        public 
    {
        feeToken = _feeToken;
        joiningFee = _fee;
        Funds.initialise();
        emit NewFee(joiningFee);
        emit NewFeeToken(feeToken);
    }

    function setJoiningFee(uint _joiningFee)
        external
        onlyOwner
    {
        joiningFee = _joiningFee;
        emit NewFee(joiningFee);
    }

    function setFeeToken(ERC20Token _feeToken)
        external
        onlyOwner
    {
        feeToken = _feeToken;
        emit NewFeeToken(feeToken);
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
        emit NewFund(AkropolisFund(msg.sender));
        // Return true if the above didn't revert
        return true;
    }

    function removeFund()
        external
    {
        // Ensure the fund is listed here
        require(Funds.contains(msg.sender), "Fund not registered");
        Funds.remove(msg.sender);
        emit RemovedFund(AkropolisFund(msg.sender));
    }

    function transferFees(address to, uint quantity)
        external
        onlyOwner
        returns(bool)
    {
        // Called by the Registry owner to transfer the fee token fees out!
        return feeToken.transfer(to, quantity);
    }

    function addUser(AkropolisFund fund)
        external
    {
        // The user adds itself to the registry
        require(Funds.contains(fund), "Fund is not in registry");
        // require the user to be in the fund
        require(fund.isMember(msg.sender), "Sender is not a member of fund");
        userToFunds[msg.sender].push(fund);
    }

    function fundSize()
        external 
        view 
        returns(uint)
    {
        // Returns the size of the funds, so we can iterate over the list of funds!
        return Funds.size();
    }

    function fundList()
        external 
        view 
        returns(address[])
    {
        return Funds.itemList();
    }

}