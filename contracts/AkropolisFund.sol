pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./Board.sol";
import "./NontransferableShare.sol";
import "./Registry.sol";
import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Unimplemented.sol";
import "./utils/Owned.sol";

contract AkropolisFund is Owned, PensionFund, NontransferableShare, Unimplemented {
    using IterableSet for IterableSet.Set;

    // The pension fund manger
    address public manager;

    // The registry that the fund will be shown on
    Registry public registry;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;
    
    uint public joiningFee;

    uint public minimumTerm;

    bytes32 public descriptionHash;

    // Tokens that this fund is approved to own.
    IterableSet.Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denominatingAsset;

    // Token in which joining fee is paid.
    ERC20Token public AkropolisToken;
    
    IterableSet.Set members;

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) public timeLock;

    // Mapping of candidate members to their join request
    mapping(address => JoinRequest) public joinRequests;

    // mapping of candidate members to their historic contributions.
    mapping(address => Contribution[]) public contributions;

    LogEntry[] public managementLog;

    //
    // structs
    //

    struct JoinRequest {
        uint unlockTime;
        ERC20Token token;
        uint initialContribution;
        uint expectedShares;
        bool pending;
    }

    struct Contribution {
        address contributor;
        address token;
        uint quantity;
        uint timestamp;
    }

    enum LogType {
        Withdrawal,
        Deposit,
        Approval
    }

    struct LogEntry {
        LogType logType;
        ERC20Token token;
        uint quantity;
        address account;
        uint code;
        string annotation;
    }

    //
    // events
    //

    // todo: more thought on this & actual use
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

    modifier onlyRegistry() {
        require(msg.sender == address(registry), "Sender is not the registry.");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Sender is not the fund manager.");
        _;
    }

    modifier timelockExpired() {
        require(now >= timeLock[msg.sender], "Sender timelock has not yet expired.");
        _;
    }

    modifier onlyMember(address account) {
        require(members.contains(account), "Sender is not a member of the fund.");
        _;
    }

    modifier onlyNotMember(address sender) {
        require(!members.contains(sender), "Sender is already a member of the fund.");
        _;
    }

    modifier noPendingJoin(address sender) {
        JoinRequest memory request = joinRequests[sender];
        require(!request.pending, "Join request pending.");
        _;
    }

    modifier onlyApprovedToken(address token) {
        require(approvedTokens.contains(token), "Token is not approved.");
        _;
    }

    constructor(
        Board _board,
        Registry _registry,
        uint _managementFeePerYear,
        uint _minimumTerm,
        uint _joiningFee,
        ERC20Token _denominatingAsset,
        ERC20Token _AkropolisToken,
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
        joiningFee = _joiningFee;
        AkropolisToken = _AkropolisToken;
        descriptionHash = _descriptionHash;
        registry = _registry;

        members.initialise();
        approvedTokens.initialise();

        // By default, the denominating asset is an approved investible token.
        denominatingAsset = _denominatingAsset;
        approvedTokens.add(denominatingAsset);

        // Register the fund on the registry, msg.sender pays for it!
        registry.addFund(msg.sender);
    }

    function setManager(address newManager) 
        external
        onlyBoard
        returns (bool)
    {
        registry.updateManager(manager, newManager);
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

    function setJoiningFee(uint newFee)
        external
        onlyBoard
        returns (bool)
    {
        joiningFee = newFee;
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

    function setDenominatingAsset(ERC20Token asset)
        external
        onlyBoard
        returns (bool)
    {
        approvedTokens.remove(denominatingAsset);
        approvedTokens.add(asset);
        denominatingAsset = asset;
    }

    function setDescriptionHash(bytes32 newHash)
        external
        onlyBoard
        returns (bool)
    {
        descriptionHash = newHash;
        return true;
    }

    function setRegistry(Registry _registry)
        external
        onlyManager
    {
        require(registry.canUpgrade(), "Cannot modify registry");
        registry = _registry;
    }

    function resetTimeLock(address user)
        external
        onlyBoard
        returns (bool)
    {
        timeLock[user] = now;
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
        return approvedTokens.itemList();
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

    // U4 - Join a new fund
    function requestJoin(address sender, uint lockupPeriod, ERC20Token token, uint contribution, uint expectedShares)
        public
        onlyRegistry
        onlyNotMember(sender)
        noPendingJoin(sender)
    {
        require(
            lockupPeriod >= minimumTerm,
            "Your lockup period is not long enough."
        );

        // Store the request on the blockchain
        joinRequests[sender] = JoinRequest(
            now + lockupPeriod,
            token,
            contribution,
            expectedShares,
            true
        );

        // Check that they have approved us for the fee
        require(
            AkropolisToken.allowance(sender, this) >= joiningFee,
            "Joining fee not approved for fund."
        );

        require(
            approvedTokens.contains(token),
            "Initial contribution is in non-approved token."
        );

        uint requirement = contribution;

        // If the initial contribution token is AKT,
        // then they must include the joining fee in their allowance.
        if (address(token) == address(AkropolisToken)) {
            requirement += joiningFee;
        }

        require(
            token.allowance(sender, this) >= requirement,
            "Insufficient allowance for initial contribution."
        );

        // Emit an event now that we've passed all the criteria for submitting a request to join
        emit newJoinRequest(sender);
    }

    function denyJoinRequest(address user)
        public
        onlyManager
    {
        delete joinRequests[user];
        registry.denyJoinRequest(user);
    }

    function cancelJoinRequest(address candidate)
        public
        onlyRegistry
        onlyNotMember(candidate)
    {
        // This is sent from the registry and already deleted on their end
        delete joinRequests[candidate];
    }

    function approveJoinRequest(address user)
        public
        onlyManager
    {
        JoinRequest memory request = joinRequests[user];

        require(
            request.pending,
            "Join request already completed or non-existent."
        );

        // Add them as a member; this must occur before calling _contribute,
        // which enforces that the recipient is a member.
        members.add(user);
        emit newMemberAccepted(user);
        // Set their in the mapping
        timeLock[user] = request.unlockTime;
  
        // Take our fees + contribution
        // This may fail if the joining fee rises, or if they have modified their allowance
        require(AkropolisToken.transferFrom(user, this, joiningFee), "Joining fee deduction failed.");

        // Make the actual contribution.
        _contribute(user, user,
                    request.token, request.initialContribution,
                    request.expectedShares);
        
        // Complete the join request.
        joinRequests[user].pending = false;
        // Add the user to the fund on the registry
        registry.approveJoinRequest(user);
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
        contributions[recipient].push(Contribution(contributor, token, quantity, now));
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
        timelockExpired
    {
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
        managementLog.push(LogEntry(LogType.Withdrawal, token, quantity, destination, result, annotation));
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
        managementLog.push(LogEntry(LogType.Approval, token, quantity, spender, result, annotation));
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
        managementLog.push(LogEntry(LogType.Deposit, token, quantity, depositor, result, annotation));
        return result;
    }

    function balanceOfToken(ERC20Token token)
        public
        view
        returns (uint)
    {
        return token.balanceOf(this);
    }
    
    function balances()
        public
        view
        returns (address[] tokens, uint[] tokenBalances)
    {
        uint numTokens = approvedTokens.size();
        uint[] memory approvedBalances = new uint[](numTokens);

        for (uint i = 0; i < numTokens; i++) {
            ERC20Token token = ERC20Token(approvedTokens.get(i));
            approvedBalances[i] = token.balanceOf(this);
        }

        return (approvedTokens.itemList(), approvedBalances);
    }
}
