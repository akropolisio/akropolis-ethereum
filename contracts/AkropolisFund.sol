pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./Board.sol";
import "./NontransferableShare.sol";
import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/FundObjects.sol";
import "./utils/Unimplemented.sol";

// The fund itself should have non-transferrable shares which represent share in the fund.
contract AkropolisFund is PensionFund, FundObjects, NontransferableShare, Unimplemented {
    using IterableSet for IterableSet.Set;

    Board public board;
    address public manager;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;

    // TODO: set this somewhere
    uint public minimumTerm;

    // TODO: let this have a setter method
    uint public joiningFee;

    // Tokens that this fund is approved to own.
    // TODO: Make this effectively public with view functions.
    IterableSet.Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denominatingAsset;

    // Token in which joining fee is paid.
    ERC20Token public AkropolisToken;
    
    // TODO: Make this effectively public with view functions.
    IterableSet.Set members;

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) public memberTimeLock;

    // The users tokens in the fund, non-transferable
    mapping(address => uint) public fundTokens;

    // Total fund tokens
    uint public totalFundTokens;

    // U9 - View a funds name
    // The name of the fund
    string public fundName;

    mapping(address => JoinRequest) joinRequests;
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

    constructor(string _name, string _symbol)
        NontransferableShare(_name, _symbol)
        public
    {
        unimplemented();
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
    {
        // POSSIBLE RACE CONDITION:
        // * User submits reasonable join request
        // * Manager reviews join request
        // * User updates join request to not be reasonable
        // * Manager approves join request based on user address, but join request has been modified and not review since then
        //
        // Way around this: something with a hash or don't allow modifications of join requests
        // Should not be an issue for now?

        require(lockupPeriod >= minimumTerm, "Your lockup period is not long enough");

        // Check that the arguments are formed correctly
        require(contributions.length == tokens.length, "tokens and contributions length differ");

        // Store the request on the blockchain
        joinRequests[msg.sender] = JoinRequest(lockupPeriod, tokens, contributions, expectedShares, false);

        // Check that they have approved us for the fee
        require(AkropolisToken.allowance(msg.sender, this) >= joiningFee, "Joining fee not approved for fund");

        // Check that they have approved us for their initial contributions
        for (uint i = 0; i < contributions.length; i++) {
            ERC20Token token = tokens[i];

            // if the token they're doing the initial contribution in is AKT, then we must subtract the joining fee from the allowance dom was here
            if (address(token) == address(AkropolisToken)) {
                require((token.allowance(msg.sender, this) - joiningFee) >= contributions[i], "initial contribution allowance not equal to argument");
            }
            require(token.allowance(msg.sender, this) >= contributions[i], "initial contribution allowance not equal to argument");
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
            request.unlockTime != 0 && !request.complete,
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
            require(token.transferFrom(msg.sender, this, contributions[i]), "Unable to withdraw contribution");
        }

        // Add them as a member
        members.add(user);
        // Emit event
        emit newMemberAccepted(user);
        // Change state to complete
        joinRequests[user].complete = true;
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
