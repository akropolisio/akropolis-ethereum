pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./Board.sol";
import "./NontransferableShare.sol";
import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Unimplemented.sol";

contract AkropolisFund is PensionFund, NontransferableShare, Unimplemented {
    using IterableSet for IterableSet.Set;

    // The pension fund manger
    address public manager;

    // The board contract, when the board wants to interact with the fund
    Board public board;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;
    
    uint public joiningFee;

    uint public minimumTerm;

    // Tokens that this fund is approved to own.
    IterableSet.Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denominatingAsset;

    // Token in which joining fee is paid.
    ERC20Token public AkropolisToken;
    
    IterableSet.Set members;

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) public memberTimeLock;

    // Mapping of candidate members to their join request
    mapping(address => JoinRequest) public joinRequests;

    // mapping of candidate members to their historic contributions.
    mapping(address => Contribution[]) public contributions;

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
        require(msg.sender == address(board), "Sender is not the Board of Directors.");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Sender is not the manager.");
        _;
    }

    modifier timelockExpired() {
        // solium-disable-next-line security/no-block-members
        require(now >= memberTimeLock[msg.sender], "Sender timelock has not yet expired.");
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
        uint _joiningFee,
        ERC20Token _denominatingAsset,
        ERC20Token _AkropolisToken,
        string _name,
        string _symbol
    )
        NontransferableShare(_name, _symbol)
        public
    {
        // Manager is null by default. A new one must be formally approved.
        board = _board;
        managementFeePerYear = _managementFeePerYear;
        minimumTerm = _minimumTerm;
        joiningFee = _joiningFee;
        AkropolisToken = _AkropolisToken;

        members.initialise();
        approvedTokens.initialise();

        // By default, the denominating asset is an approved investible token.
        denominatingAsset = _denominatingAsset;
        approvedTokens.add(denominatingAsset);
    }

    function setManager(address newManager) 
        external
        onlyBoard
        returns (bool)
    {
        manager = newManager;
        return true;
    }

    function setBoard(Board newBoard)
        external
        onlyBoard
        returns (bool)
    {
        board = newBoard;
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

    function _setDenominatingAsset(ERC20Token asset)
        internal
    {
        approvedTokens.remove(denominatingAsset);
        approvedTokens.add(asset);
        denominatingAsset = asset;
    }

    function setDenominatingAsset(ERC20Token asset)
        external
        onlyBoard
        returns (bool)
    {
        _setDenominatingAsset(asset);
    }

    function resetMemberTimeLock(address user)
        external
        onlyBoard
        returns (bool)
    {
        memberTimeLock[user] = now;
    }

    function approveTokens(ERC20Token[] tokens)
      external
      onlyBoard
    {
        for (uint i; i < tokens.length; i++) {
            approvedTokens.add(address(tokens[i]));
        }
    }

    function removeTokens(ERC20Token[] tokens)
      external
      onlyBoard
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

    // U4 - Join a new fund
    function joinFund(uint lockupPeriod, ERC20Token token, uint contribution, uint expectedShares)
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
            // solium-disable-next-line security/no-block-members
            now + lockupPeriod,
            token,
            contribution,
            expectedShares,
            true
        );

        // Check that they have approved us for the fee
        require(
            AkropolisToken.allowance(msg.sender, this) >= joiningFee,
            "Joining fee not approved for fund."
        );

        require(
            approvedTokens.contains(token),
            "Initial contribution is in non-approved token."
        );

        uint allowance = token.allowance(msg.sender, this);
        uint requirement = contribution;

        // If the initial contribution token is AKT,
        // then they must include the joining fee in their allowance.
        if (address(token) == address(AkropolisToken)) {
            requirement += joiningFee;
        }

        require(
            token.allowance(msg.sender, this) >= requirement,
            "Insufficient allowance for nitial contribution."
        );

        // Emit an event now that we've passed all the criteria for submitting a request to join
        emit newJoinRequest(msg.sender);
    }

    function DisapproveJoinRequest(address user)
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
        memberTimeLock[user] = request.unlockTime;
  
        // Take our fees + contribution
        // This may fail if the joining fee rises, or if they have modified their allowance
        require(AkropolisToken.transferFrom(user, this, joiningFee), "Joining fee deduction failed.");

        // Make the actual contribution.
        _contribute(user, user,
                    request.token, request.initialContribution,
                    request.expectedShares);
        
        // Give the user their requested shares in the fund
        _createShares(user, request.expectedShares);

        // Complete the join request.
        joinRequests[user].pending = false;

    }

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
        contributions[recipient].push(Contribution(contributor, token, quantity));
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

    function balanceOfToken()
        public
        view
        returns (uint)
    {
        unimplemented();
    }

    function fundBalances()
        public
        view
        returns (uint[])
    {
        unimplemented();
    }
}
