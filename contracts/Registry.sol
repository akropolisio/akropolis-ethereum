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
    IterableSet.Set funds;

    // List the funds a user is in
    mapping(address => IterableSet.Set) internal _userFunds;
    mapping(address => IterableSet.Set) internal _userRequests;
    mapping(address => IterableSet.Set) internal _managerFunds;

    event NewFund(AkropolisFund indexed fund);
    event RemovedFund(AkropolisFund indexed fund);
    event NewFee(uint indexed newFee);
    event NewFeeToken(ERC20Token indexed newFeeToken);
    event UpdatedManager(AkropolisFund indexed fund, address oldManager, address newManager);
    event CanUpgrade();

    constructor(ERC20Token _feeToken, uint _fee)
        Owned(msg.sender)
        public 
    {
        feeToken = _feeToken;
        joiningFee = _fee;
        funds.initialise();
        emit NewFee(joiningFee);
        emit NewFeeToken(feeToken);
    }

    modifier onlyRegisteredFund(address fund) {
        // This error is sometimes misleading!!
        // The sender is sometimes the `fund` and other times it is a parameter!
        require(funds.contains(fund), "Fund is not in registry");
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

    // This function is called by the fund itself during construction.
    function addFund(address payer)
        external 
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
        require(!funds.contains(msg.sender), "Fund already registered");
        // Add the fund to the set
        funds.add(msg.sender);
        // Emit an event for successfully adding a new fund
        emit NewFund(AkropolisFund(msg.sender));
    }

    // A user joins a fund by sending a request to join a fund to the registry
    function requestMembership(AkropolisFund fund, uint lockupDuration, uint recurPayment, uint paymentFreq,
                               uint payoutDuration, uint contribution, uint expectedShares)
        external 
        onlyRegisteredFund(fund)
    {
        // The following should revert if they have already sent a request or are a member
        // hence no additional checks are done
        fund.requestMembership(msg.sender, lockupDuration, recurPayment, paymentFreq, payoutDuration, contribution, expectedShares);
        IterableSet.Set storage requests = _userRequests[msg.sender];
        if (!requests.isInitialised()) {
            requests.initialise();
        }
        requests.add(fund);
    }

    // A fund sends this to registry after approving the request
    function approveJoinRequest(address user)
        external 
        onlyRegisteredFund(msg.sender)
    {
        IterableSet.Set storage requests = _userRequests[user];
        // We do not need to init this set as it would have already been init'd
        // or it will revert if it hasn't like it should!
        require(requests.contains(msg.sender), "User must have sent a request");
        requests.remove(user);
        IterableSet.Set storage usersFunds = _userFunds[user];
        if (!usersFunds.isInitialised()) {
            usersFunds.initialise();
        }
        usersFunds.add(msg.sender);
    }

    function cancelJoinRequest(AkropolisFund fund)
        external
    {
        IterableSet.Set storage requests = _userRequests[msg.sender];
        // Likewise here,  we do not have the init the set as it should have
        // been inited by request join already
        require(requests.contains(address(fund)), "User must have sent a request");
        requests.remove(address(fund));
        fund.cancelJoinRequest(msg.sender);
    }

    function denyJoinRequest(address user)
        external
        onlyRegisteredFund(msg.sender)
    {
        IterableSet.Set storage requests = _userRequests[user];
        require(requests.contains(msg.sender), "User must have sent a request");
        requests.remove(msg.sender);
    }

    function updateManager(address oldManager, address newManager)
        external
        onlyRegisteredFund(msg.sender)
    {
        IterableSet.Set storage managedFunds = _managerFunds[oldManager];
        // If the manager is being tracked
        if (managedFunds.isInitialised()) {
            managedFunds.remove(msg.sender);
        }
        IterableSet.Set storage newManagedFunds = _managerFunds[newManager];
        if (!newManagedFunds.isInitialised()) {
            newManagedFunds.initialise();
        }
        newManagedFunds.add(msg.sender);
        emit UpdatedManager(AkropolisFund(msg.sender), oldManager, newManager);
    }

    function managerFunds(address manager)
        external
        view
        returns (address[])
    {
        IterableSet.Set storage managedFunds = _managerFunds[manager];
        return managedFunds.array();
    }

    // For the owner to remove a fund
    function removeFund(AkropolisFund fund) 
        external
        onlyOwner
    {
        require(funds.remove(address(fund)), "Fund not registered");
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

    function numFunds()
        external 
        view 
        returns(uint)
    {
        // Returns the size of the funds, so we can iterate over the list of funds!
        return funds.size();
    }

    function fundList()
        external 
        view 
        returns(address[])
    {
        return funds.array();
    }

    function userFundsLength(address user)
        external
        view
        returns(uint)
    {
        if (_userFunds[user].isInitialised()){
            return _userFunds[user].size();
        }
        return 0;
    }

    function userFundsList(address user)
        external
        view
        returns(address[])
    {
        return _userFunds[user].array();
    }

}