pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./Board.sol";
import "./Ticker.sol";
import "./NontransferableShare.sol";
import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Unimplemented.sol";
import "./utils/Owned.sol";

contract AkropolisFund is Owned, PensionFund, NontransferableShare, Unimplemented {
    using IterableSet for IterableSet.Set;

    // The pension fund manger
    address public manager;

    // The ticker to source price data from
    Ticker public ticker;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;
    
    uint public minimumTerm;

    bytes32 public descriptionHash;

    // Tokens that this fund is approved to own.
    IterableSet.Set approvedTokens;

    // Tokens with nonzero balances.
    IterableSet.Set ownedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denomination;

    // Token in which joining fee is paid.
    IterableSet.Set members;

    mapping(address => UserDetails) public userDetails;

    // Mapping of candidate members to their join request
    mapping(address => JoinRequest) public joinRequests;

    // mapping of candidate members to their historic contributions.
    mapping(address => Contribution[]) public contributions;

    LogEntry[] public managementLog;

    //
    // structs
    //

    struct JoinRequest {
        uint timestamp;
        uint lockupDuration;
        uint recurringPayment;
        uint paymentFrequency;
        uint initialContribution;
        uint expectedShares;
        bool pending;
    }

    struct Contribution {
        address contributor;
        uint timestamp;
        ERC20Token token;
        uint quantity;
    }

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    // In addition they have a payment frequency, and the fund may make withdrawals of 
    // a given quantity from the user's account at no greater than the specified frequency.
    struct UserDetails {
        uint unlockTime;
        uint joinTime;
        uint recurringPayment;
        uint paymentFrequency;
        uint lastRecurringContribution;
    }

    enum LogType {
        Withdrawal,
        Deposit,
        Approval
    }

    struct LogEntry {
        LogType logType;
        uint timestamp;
        ERC20Token token;
        uint quantity;
        address account;
        uint code;
        string annotation;
    }

    //
    // events
    //

    event Withdraw(address indexed user, uint indexed amount);
    event ApproveToken(address indexed ERC20Token);
    event RemoveToken(address indexed ERC20Token);
    event newJoinRequest(address indexed from);
    event newMemberAccepted(address indexed user);

    // 
    // modifiers
    //

    modifier onlyBoard() {
        require(msg.sender == address(board()), "Sender is not the Board of Directors.");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Sender is not the fund manager.");
        _;
    }

    modifier onlyMember(address account) {
        require(members.contains(account), "Sender is not a member of the fund.");
        _;
    }

    modifier onlyNotMember() {
        require(!members.contains(msg.sender), "Sender is already a member of the fund.");
        _;
    }

    modifier noPendingJoin() {
        JoinRequest memory request = joinRequests[msg.sender];
        require(!request.pending, "Join request pending.");
        _;
    }

    modifier onlyApprovedToken(address token) {
        require(approvedTokens.contains(token), "Token is not approved.");
        _;
    }

    constructor(
        Board _board,
        uint _managementFeePerYear,
        uint _minimumTerm,
        ERC20Token _denomination,
        string _name,
        string _symbol,
        bytes32 _descriptionHash
    )
        Owned(_board)
        NontransferableShare(_name, _symbol)
        public
    {
        // Manager is null by default. A new one must be formally approved.
        managementFeePerYear = _managementFeePerYear;
        minimumTerm = _minimumTerm;
        descriptionHash = _descriptionHash;

        members.initialise();
        approvedTokens.initialise();
        ownedTokens.initialise();

        // By default, the denominating asset is an approved investible token.
        denomination = _denomination;
        approvedTokens.add(_denomination);
    }

    function setManager(address newManager) 
        external
        onlyBoard
        returns (bool)
    {
        manager = newManager;
        return true;
    }

    function nominateNewBoard(Board newBoard)
        external
        onlyBoard
        returns (bool)
    {
        nominateNewOwner(address(newBoard));
        return true;
    }

    function setManagementFee(uint newFee)
        external
        onlyBoard
        returns (bool)
    {
        managementFeePerYear = newFee;
        return true;
    }

    function setMinimumTerm(uint newTerm)
        external
        onlyBoard
        returns (bool)
    {
        minimumTerm = newTerm;
        return true;
    }

    function setDenomination(ERC20Token token)
        external
        onlyBoard
        returns (bool)
    {
        approvedTokens.remove(denomination);
        approvedTokens.add(token);
        denomination = token;
    }

    function setDescriptionHash(bytes32 newHash)
        external
        onlyBoard
        returns (bool)
    {
        descriptionHash = newHash;
        return true;
    }

    function resetTimeLock(address user)
        external
        onlyBoard
        returns (bool)
    {
        userDetails[user].unlockTime = now;
    }

    function approveTokens(ERC20Token[] tokens)
      external
      onlyBoard
      returns (bool)
    {
        for (uint i; i < tokens.length; i++) {
            approvedTokens.add(address(tokens[i]));
        }
    }

    function disapproveTokens(ERC20Token[] tokens)
      external
      onlyBoard
      returns (bool)
    {
        for (uint i; i < tokens.length; i++) {
            approvedTokens.remove(address(tokens[i]));
        }
    }

    function isApprovedToken(address token) 
        external
        view
        returns (bool)
    {
        return approvedTokens.contains(token);
    }

    function numApprovedTokens()
        external
        view
        returns (uint)
    {
        return approvedTokens.size();
    }

    function approvedToken(uint i)
        external
        view
        returns (address)
    {
        return approvedTokens.get(i);
    }
    
    function getApprovedTokens()
        external
        view
        returns (address[])
    {
        return approvedTokens.array();
    }

    function isMember(address user)
        external
        view
        returns (bool)
    {
        return members.contains(user);
    }

    function numMembers()
        external
        view
        returns (uint)
    {
        return members.size();
    }

    function member(uint i)
        external
        view
        returns (address)
    {
        return members.get(i);
    }

    function board()
        public
        view
        returns (Board)
    {
        return Board(owner);
    }

    function managementLogLength()
        public
        view
        returns (uint)
    {
        return managementLog.length;
    }

    function unlockTime(address user)
        public
        view
        returns (uint)
    {
        return userDetails[user].unlockTime;
    }

    function joinTime(address user)
        public
        view
        returns (uint)
    {
        return userDetails[user].joinTime;
    }

    function recurringPayment(address user)
        public
        view
        returns (uint)
    {
        return userDetails[user].recurringPayment;
    }

    function paymentFrequency(address user)
        public
        view
        returns (uint)
    {
        return userDetails[user].paymentFrequency;
    }

    function lastRecurringContribution(address user)
        public
        view
        returns (uint)
    {
        return userDetails[user].lastRecurringContribution;
    }

    function joinFund(uint lockupPeriod, uint recurPayment, uint paymentFreq, uint contribution, uint expectedShares)
        public
        onlyNotMember
        noPendingJoin
    {
        require(
            lockupPeriod >= minimumTerm,
            "Your lockup period is not long enough."
        );

        // Store the request on the blockchain
        joinRequests[msg.sender] = JoinRequest(
            now,
            lockupPeriod,
            recurPayment,
            paymentFreq,
            contribution,
            expectedShares,
            true
        );

        require(
            denomination.allowance(msg.sender, this) >= contribution,
            "Insufficient allowance for initial contribution."
        );

        // Emit an event now that we've passed all the criteria for submitting a request to join
        emit newJoinRequest(msg.sender);
    }

    function acceptRecurringPayment(address user)
        public
    {
        unimplemented();
    }

    function denyJoinRequest(address user)
        public
        onlyManager
    {
        delete joinRequests[user];
    }

    function cancelJoinRequest()
        public
        onlyNotMember
    {
        delete joinRequests[msg.sender];
    }

    function _maybeAddOwnedToken(ERC20Token token)
        internal
    {
        if (!ownedTokens.contains(token)) {
            if(token.balanceOf(this) > 0) {
                ownedTokens.add(token);
            }
        }
    }

    function _maybeRemoveOwnedToken(ERC20Token token)
        internal
    {
        if (ownedTokens.contains(token)) {
            if(token.balanceOf(this) == 0) {
                ownedTokens.remove(token);
            }
        }
    }

    function approveJoinRequest(address user)
        public
        onlyManager
    {
        JoinRequest storage request = joinRequests[user];

        require(
            request.pending,
            "Join request already completed or non-existent."
        );

        // Add them as a member; this must occur before calling _contribute,
        // which enforces that the recipient is a member.
        members.add(user);
        emit newMemberAccepted(user);
        // Set their details in the mapping
        UserDetails storage details = userDetails[user];
        details.unlockTime = now + request.lockupDuration;
        details.joinTime = now;
        details.recurringPayment = request.recurringPayment;
        details.paymentFrequency = details.paymentFrequency;

        // Make the actual contribution.
        uint initialContribution = request.initialContribution;
        if (initialContribution > 0) {
            _contribute(user, user,
                        denomination, initialContribution,
                        request.expectedShares);
        }
        
        // Complete the join request.
        joinRequests[user].pending = false;
    }
    
    // TODO: This should go through a proper request system instead of just issuing
    // the requested shares unchallenged.
    function _contribute(address contributor, address recipient, ERC20Token token,
                         uint quantity, uint expectedShares)
        internal
        onlyMember(recipient)
        onlyApprovedToken(token)
    {
        require(
            token.transferFrom(contributor, this, quantity),
            "Unable to withdraw contribution."
        );
        _maybeAddOwnedToken(token);
        contributions[recipient].push(Contribution(contributor, now, token, quantity));
        _createShares(recipient, expectedShares);
    }

    // U6 - Must make a contribution to a fund if already a member
    function makeContribution(ERC20Token token, uint quantity, uint expectedShares)
        public
    {
        _contribute(msg.sender, msg.sender, token, quantity, expectedShares);
    }

    function makeContributionFor(address recipient, ERC20Token token, uint quantity, uint expectedShares)
        public
    {
        _contribute(msg.sender, recipient, token, quantity, expectedShares);
    }

    // U18 - Withdraw from a fund if my timelock has expired
    function withdrawBenefits()
        public
        onlyMember(msg.sender)
    {
        require(now >= userDetails[msg.sender].unlockTime, "Sender timelock has not yet expired.");
        unimplemented();
    }

    function withdrawFees()
        public
        onlyManager
    {
        unimplemented();
    }

    // TODO: Make these manager functions two-stage so that, for example, large
    // transfers might require board approval before they go through.
    function withdraw(ERC20Token token, address destination, uint quantity, string annotation)
        external
        onlyManager
        returns (uint)
    {
        // TODO: check the Governor if this withdrawal is permitted.
        require(bytes(annotation).length > 0, "No annotation provided.");
        uint result = token.transfer(destination, quantity) ? 0 : 1;
        _maybeRemoveOwnedToken(token);
        managementLog.push(LogEntry(LogType.Withdrawal, now, token, quantity, destination, result, annotation));
        return result;
    }

    function approveWithdrawal(ERC20Token token, address spender, uint quantity, string annotation)
        external
        onlyManager
        returns (uint)
    {
        // TODO: check the Governor if this approval is permitted.
        require(bytes(annotation).length > 0, "No annotation provided.");
        uint result = token.approve(spender, quantity) ? 0 : 1;
        managementLog.push(LogEntry(LogType.Approval, now, token, quantity, spender, result, annotation));
        return result;
    }

    function deposit(ERC20Token token, address depositor, uint quantity, string annotation)
        external
        onlyManager
        returns (uint)
    {
        // TODO: check the Governor if this deposit is permitted.
        require(bytes(annotation).length > 0, "No annotation provided.");
        require(token.allowance(depositor, this) >= quantity, "Insufficient depositor allowance.");
        uint result = token.transferFrom(depositor, this, quantity) ? 0 : 1;
        _maybeAddOwnedToken(token);
        managementLog.push(LogEntry(LogType.Deposit, now, token, quantity, depositor, result, annotation));
        return result;
    }

    function balanceOfToken(ERC20Token token)
        public
        view
        returns (uint)
    {
        return token.balanceOf(this);
    }

    function balanceValueOfToken(ERC20Token token)
        public
        view
        returns (uint)
    {
        return ticker.value(token, token.balanceOf(this));
    }

    function _balances()
        internal
        view
        returns (ERC20Token[] tokens, uint[] tokenBalances)
    {
        uint numTokens = ownedTokens.size();
        uint[] memory bals = new uint[](numTokens);
        ERC20Token[] memory toks = new ERC20Token[](numTokens);

        for (uint i; i < numTokens; i++) {
            ERC20Token token = ERC20Token(approvedTokens.get(i));
            bals[i] = token.balanceOf(this);
            toks[i] = token;
        }

        return (toks, bals);
    }

    function balances()
        public
        view
        returns (ERC20Token[] tokens, uint[] tokenBalances)
    {
        return _balances();
    }

    function balanceValues()
        public
        view
        returns (ERC20Token[] tokens, uint[] tokenValues)
    {
        (ERC20Token[] memory toks, uint[] memory bals) = _balances();
        return (toks, ticker.values(toks, bals));
    }

    function fundValue()
        public
        view
        returns (uint)
    {
        (ERC20Token[] memory toks, uint[] memory bals) = _balances();
        uint[] memory vals = ticker.values(toks, bals);

        uint total;
        for (uint i; i < vals.length; i++) {
            total += vals[i];
        }
        return total;
    }
}
