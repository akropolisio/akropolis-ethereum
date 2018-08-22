pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./Board.sol";
import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Unimplemented.sol";

// The fund itself should have non-transferable shares which represent share in the fund.
contract AkropolisFund is PensionFund, Unimplemented {
    using IterableSet for IterableSet.Set;

    // The pension fund manger
    address public manager;

    // The board contract, when the board wants to interact with the fund
    Board public board;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;

    // TODO: set this somewhere
    uint public minimumTerm;

    // TODO: let this have a setter method
    uint public joiningFee;

    // Total fund tokens
    uint public totalFundTokens;

    // Tokens that this fund is approved to own.
    // TODO: Make this effectively public with view functions.
    IterableSet.Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denominatingAsset;

    // Token in which joining fee is paid.
    ERC20Token public AkropolisToken;
    
    // TODO: Make this effectively public with view functions.
    IterableSet.Set members;

    // U9 - View a funds name
    // The name of the fund
    string public fundName;

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) public memberTimeLock;

    // The users tokens in the fund, non-transferable
    mapping(address => uint) public fundTokens;

    // Mapping of candidate members to their join request
    mapping(address => JoinRequest) joinRequests;

    //
    // structs
    //

    struct JoinRequest {
        uint unlockTime;
        ERC20Token[] tokens;
        uint[] contributions;
        uint expectedShares;
        bool pending;
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

    modifier onlyMember() {
        require(members.contains(msg.sender), "Sender is not a member of the fund.");
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

    constructor(
        Board _board,
        uint _managementFeePerYear,
        uint _minimumTerm,
        uint _joiningFee,
        ERC20Token _denominatingAsset,
        ERC20Token _AkropolisToken,
        string _fundName
    )
      public
    {
        manager = msg.sender;
        board = _board;
        managementFeePerYear = _managementFeePerYear;
        minimumTerm = _minimumTerm;
        joiningFee = _joiningFee;
        denominatingAsset = _denominatingAsset;
        AkropolisToken = _AkropolisToken;
        fundName = _fundName;
    }

    function setManager(address newManager) 
        external
        onlyBoard
        returns (bool)
    {
        manager = newManager;
        return true;
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

    // U4 - Join a new fund
    function joinFund(uint lockupPeriod, ERC20Token[] tokens, uint[] contributions, uint expectedShares)
        public
        onlyNotMember
        noPendingJoin
    {
        require(lockupPeriod >= minimumTerm, "Your lockup period is not long enough");

        // Check that the arguments are formed correctly
        require(contributions.length == tokens.length, "tokens and contributions length differ");

        // Store the request on the blockchain
        joinRequests[msg.sender] = JoinRequest(
            // solium-disable-next-line security/no-block-members
            now + lockupPeriod,
            tokens,
            contributions,
            expectedShares,
            true
        );

        // Check that they have approved us for the fee
        require(
            AkropolisToken.allowance(msg.sender, this) >= joiningFee,
            "Joining fee not approved for fund"
        );

        // Check that they have approved us for their initial contributions
        for (uint i = 0; i < contributions.length; i++) {
            ERC20Token token = tokens[i];

            // ensure the token is approved
            require(approvedTokens.contains(token), "Request includes non-approved token");

            // if the token they're doing the initial contribution in is AKT, then we must subtract the 
            // joining fee from the allowance dom was here
            if (address(token) == address(AkropolisToken)) {
                uint allowanceWithoutJoiningFee = token.allowance(msg.sender, this) - joiningFee;
                require(
                    allowanceWithoutJoiningFee >= contributions[i],
                    "initial contribution allowance not equal to argument"
                );
            }
            require(
                token.allowance(msg.sender, this) >= contributions[i],
                "initial contribution allowance not equal to argument"
            );
        }

        // Emit an event now that we've passed all the criteria for submitting a request to join
        emit newJoinRequest(msg.sender);
    }

    function approveJoinRequest(address user)
        public
        onlyManager
    {
        // Read information about request
        JoinRequest memory request = joinRequests[user];

        require(
            request.unlockTime != 0 && request.pending,
            "Join request already completed or non-existant."
        );

        // Take our fees + contribution
        // This may fail if the joining fee rises, or if they have modified their allowance
        require(AkropolisToken.transferFrom(msg.sender, this, joiningFee), "Joining fee deduction failed");

        ERC20Token[] memory tokens = request.tokens;
        uint[] memory contributions = request.contributions;

        // Transfer their initial contribution to the fund
        for (uint i = 0; i < contributions.length; i++) {
            ERC20Token token = tokens[i];
            // ensure the token is approved
            require(approvedTokens.contains(token), "Request includes non-approved token");
            require(
                token.transferFrom(msg.sender, this, contributions[i]),
                "Unable to withdraw contribution"
            );
        }

        // Add them as a member
        members.add(user);
        // Emit event
        emit newMemberAccepted(user);
        // Change state to complete
        joinRequests[user].pending = false;
        // Set their in the mapping
        memberTimeLock[user] = request.unlockTime;
    }


    // U6 - Must make a contribution to a fund if already a member
    function makeContribution()
        public
        onlyMember
    {
        unimplemented();
    }

    // U18 - Withdraw from a fund if my timelock has expired
    function withdrawBenefits()
        public
        onlyMember
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

    function executeRequest()
        public
        onlyManager
    {
        unimplemented();
    }
    
    function cancelRequest()
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
