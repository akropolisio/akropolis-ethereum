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

    // The fee cost to register a new fund.
    uint public fundRegistrationFee;

    // The cost for a fund to register a new user.
    uint public userRegistrationFee;

    // The set of addresses approved to create new funds.
    IterableSet.Set sponsors;

    // Iterable set of funds
    IterableSet.Set funds;

    // List the funds a user is in
    mapping(address => IterableSet.Set) internal _userFunds;
    mapping(address => IterableSet.Set) internal _userRequests;
    mapping(address => IterableSet.Set) internal _managerFunds;

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
        funds.initialise();
        sponsors.initialise();
        emit NewFundRegistrationFee(_fundRegistrationFee);
        emit NewFeeToken(_feeToken);
    }

    modifier onlyRegisteredFund(address fund) {
        // This error is sometimes misleading!!
        // The sender is sometimes the `fund` and other times it is a parameter!
        require(funds.contains(fund), "Fund is not in registry");
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
        sponsors.add(sponsor);
    }

    function removeSponsor(address sponsor)
        public
        onlyOwner
    {
        sponsors.remove(sponsor);
    }

    function isSponsor(address sponsor)
        public
        view
        returns (bool isApproved)
    {
        return sponsors.contains(sponsor);
    }


    // This function is called by the fund itself during construction.
    function addFund(address payer)
        external 
    {
        // Take the fee, payer must have paid allowance first
        // this will probably be the person deploying the fund!
        // This is easier than making the fund itself (msg.sender) pay for the fund
        // because it is called during construction of the fund
        uint fee = fundRegistrationFee;
        if (fee > 0) {
            require(feeToken.allowance(payer, this) >= fee && feeToken.transferFrom(payer, this, fee),
                    "Failed to receive fee payment.");
        }

        // Ensure the fund isn't already listed here
        require(!funds.contains(msg.sender), "Fund already registered.");
        // Add the fund to the set
        funds.add(msg.sender);
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
        IterableSet.Set storage requests = _userRequests[msg.sender];
        if (!requests.isInitialised()) {
            requests.initialise();
        }
        requests.add(fund);
    }

    // A fund sends this to registry after approving the request
    function approveMembershipRequest(address user)
        external 
        onlyRegisteredFund(msg.sender)
    {
        IterableSet.Set storage requests = _userRequests[user];
        require(requests.contains(msg.sender), "User must have sent a request");

        uint fee = userRegistrationFee;
        if (fee > 0) {
            require(feeToken.allowance(msg.sender, this) >= fee && feeToken.transferFrom(msg.sender, this, fee),
                    "Failed to receive fee payment.");
        }

        requests.remove(user);
        IterableSet.Set storage usersFunds = _userFunds[user];
        if (!usersFunds.isInitialised()) {
            usersFunds.initialise();
        }
        usersFunds.add(msg.sender);
    }

    function cancelMembershipRequest(AkropolisFund fund)
        external
    {
        IterableSet.Set storage requests = _userRequests[msg.sender];
        require(requests.contains(address(fund)), "User must have sent a request");
        requests.remove(address(fund));
        fund.cancelMembershipRequest(msg.sender);
    }

    function denyMembershipRequest(address user)
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