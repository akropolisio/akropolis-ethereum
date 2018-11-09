/*
* The MIT License
*
* Copyright (c) 2017-2018 , Akropolis Decentralised Ltd (Gibraltar), http://akropolis.io
*
*/

pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./AkropolisFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/Set.sol";
import "./utils/Owned.sol";

contract Registry is Owned {
    using AddressSet for AddressSet.Set;

    // This will typically be the Akropolis Token
    ERC20Token public feeToken;

    // The fee cost to register a new fund.
    uint public fundRegistrationFee;

    // The cost for a fund to register a new user.
    uint public userRegistrationFee; // TODO: rename to membershipFee

    // The set of addresses approved to create new funds.
    AddressSet.Set _sponsors;

    // Iterable set of funds
    AddressSet.Set _funds;

    // List the funds a user is in
    mapping(address => AddressSet.Set) internal _userFunds;
    mapping(address => AddressSet.Set) internal _userRequests;
    mapping(address => AddressSet.Set) internal _managerFunds;

    event NewFund(AkropolisFund indexed fund);
    event RemovedFund(AkropolisFund indexed fund);
    event NewFundRegistrationFee(uint indexed newFee);
    event NewUserRegistrationFee(uint indexed newFee);
    event NewFeeToken(ERC20Token indexed newFeeToken);
    event UpdatedManager(AkropolisFund indexed fund, address indexed oldManager, address indexed newManager);
    event CanUpgrade();

    constructor(ERC20Token _feeToken, uint _fundRegistrationFee, uint _userRegistrationFee)
        Owned(msg.sender)
        public 
    {
        feeToken = _feeToken;
        fundRegistrationFee = _fundRegistrationFee;
        userRegistrationFee = _userRegistrationFee;
        _funds.initialise();
        _sponsors.initialise();
        emit NewFundRegistrationFee(_fundRegistrationFee);
        emit NewFeeToken(_feeToken);
    }

    modifier onlyRegisteredFund(address fund) {
        require(_funds.contains(fund), "Unregistered fund.");
        _;
    }

    function setFundRegistrationFee(uint _fundRegistrationFee)
        external
        onlyOwner
    {
        fundRegistrationFee = _fundRegistrationFee;
        emit NewFundRegistrationFee(_fundRegistrationFee);
    }

    function setUserRegistrationFee(uint _userRegistrationFee)
        external
        onlyOwner
    {
        userRegistrationFee = _userRegistrationFee;
        emit NewUserRegistrationFee(_userRegistrationFee);
    }

    function setFeeToken(ERC20Token _feeToken)
        external
        onlyOwner
    {
        feeToken = _feeToken;
        emit NewFeeToken(_feeToken);
    }

    function addSponsor(address sponsor)
        public
        onlyOwner
    {
        _sponsors.add(sponsor);
    }

    function removeSponsor(address sponsor)
        public
        onlyOwner
    {
        _sponsors.remove(sponsor);
    }

    function isSponsor(address sponsor)
        public
        view
        returns (bool isApproved)
    {
        return _sponsors.contains(sponsor);
    }

    function _checkRequestExists(AddressSet.Set storage requests, address fund)
        internal
        view
    {
        require(requests.contains(fund), "No such request.");
    }

    function _withdrawFee(address payer, uint fee)
        internal
    {
        if (fee > 0) {
            require(feeToken.allowance(payer, this) >= fee && feeToken.transferFrom(payer, this, fee),
                    "Fee transfer failed.");
        }
    }

    // This function is called by the fund itself during construction.
    function addFund(address payer)
        external 
    {
        // Take the fee, payer must have set the allowance first.
        // this will probably be the person deploying the fund!
        // This is easier than making the fund itself (msg.sender) pay for the fund
        // because it is called during construction of the fund
        _withdrawFee(payer, fundRegistrationFee);

        // Ensure the fund isn't already listed here
        require(!_funds.contains(msg.sender), "Fund already registered.");
        // Add the fund to the set
        _funds.add(msg.sender);
        // Emit an event for successfully adding a new fund
        emit NewFund(AkropolisFund(msg.sender));
    }

    // A user joins a fund by sending a membership request to the registry
    function requestMembership(AkropolisFund fund, uint lockupDuration, uint payoutDuration,
                               uint initialContribution, uint expectedShares, bool setupSchedule,
                               uint scheduledContribution, uint scheduleDelay, uint scheduleDuration)
        external 
        onlyRegisteredFund(fund)
    {
        // The following should revert if they have already sent a request or are a member
        // hence no additional checks are done
        fund.requestMembership(msg.sender, lockupDuration, payoutDuration,
                               initialContribution, expectedShares, setupSchedule,
                               scheduledContribution, scheduleDelay, scheduleDuration);
        AddressSet.Set storage requests = _userRequests[msg.sender];
        if (!requests.isInitialised()) {
            requests.initialise();
        }
        requests.add(fund);
    }

    function cancelMembershipRequest(AkropolisFund fund)
        external
    {
        AddressSet.Set storage requests = _userRequests[msg.sender];
        _checkRequestExists(requests, fund);
        requests.remove(address(fund));
        fund.cancelMembershipRequest(msg.sender);
    }

    // A fund sends this to registry after approving the request
    function approveMembershipRequest(address user)
        external 
        onlyRegisteredFund(msg.sender)
    {
        AddressSet.Set storage requests = _userRequests[user];

        _checkRequestExists(requests, msg.sender);
        _withdrawFee(msg.sender, userRegistrationFee);

        requests.remove(user);
        AddressSet.Set storage usersFunds = _userFunds[user];
        if (!usersFunds.isInitialised()) {
            usersFunds.initialise();
        }
        usersFunds.add(msg.sender);
    }

    function denyMembershipRequest(address user)
        external
        onlyRegisteredFund(msg.sender)
    {
        AddressSet.Set storage requests = _userRequests[user];
        _checkRequestExists(requests, msg.sender);
        requests.remove(msg.sender);
    }

    function updateManager(address oldManager, address newManager)
        external
        onlyRegisteredFund(msg.sender)
    {
        AddressSet.Set storage managedFunds = _managerFunds[oldManager];
        // If the manager is being tracked
        if (managedFunds.isInitialised()) {
            managedFunds.remove(msg.sender);
        }
        AddressSet.Set storage newManagedFunds = _managerFunds[newManager];
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
        AddressSet.Set storage managedFunds = _managerFunds[manager];
        return managedFunds.array();
    }

    // For the owner to remove a fund
    function removeFund(AkropolisFund fund) 
        external
        onlyOwner
        onlyRegisteredFund(fund)
    {
        _funds.remove(address(fund));
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
        return _funds.size();
    }

    function funds()
        external 
        view 
        returns(address[])
    {
        return _funds.array();
    }

    function getFund(uint i)
        external
        view
        returns (AkropolisFund)
    {
        return AkropolisFund(_funds.get(i));
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
