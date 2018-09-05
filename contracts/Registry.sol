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
    mapping(address => IterableSet.Set) internal userToRequests;

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

    modifier onlyRegistered(address fund) {
        require(Funds.contains(fund), "fund address not registered");
        _;
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

    // This function is called by the fund itself!
    function addFund(address payer)
        external 
        returns(bool)
    {
        // Take the fee, payer must have paid allowance first
        // this will probably be the person deploying the fund!
        // This is easier than making the fund itself (msg.sender) pay for the fund
        // because it is called during construction of the fund
        require(
            feeToken.transferFrom(payer, this, joiningFee),
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

    // A user joins a fund by sending a request to join a fund to the registry
    function joinFund(AkropolisFund fund, uint lockupPeriod, ERC20Token token, uint contribution,
                      uint expectedShares)
        public
        onlyRegistered(fund)
    {
        // we need to store some kind of marker here that the sender has sent the 
        fund.joinFund(msg.sender, lockupPeriod, token, contribution, expectedShares);
        IterableSet.Set storage requests = userToRequests[msg.sender];
        if (!requests.isInitialised()) {
            requests.initialise();
        }
        requests.add(fund);
    }

    // A fund sends this to registry after approving the request
    function approveJoinRequest(address user)
        public
        onlyRegistered(msg.sender)
    {
        IterableSet.Set storage requests = userToRequests[user];
        require(requests.contains(user), "User must have sent a request");
        requests.remove(user);
        userToFunds[user].push(AkropolisFund(msg.sender));
    }

    // Not sure about this one
    function removeFund()
        external
    {
        // Ensure the fund is listed here
        require(Funds.contains(msg.sender), "Fund not registered");
        Funds.remove(msg.sender);
        emit RemovedFund(AkropolisFund(msg.sender));
    }

    // We should make a more generic way of doing this for other contracts with the same functionality
    function transferFees(address to, uint quantity)
        external
        onlyOwner
        returns(bool)
    {
        // Called by the Registry owner to transfer the fee token fees out!
        return feeToken.transfer(to, quantity);
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