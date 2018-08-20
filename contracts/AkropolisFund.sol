pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./Board.sol";

// The fund itself should have non-transferrable shares which represent share in the fund.
contract AkropolisFund is PensionFund {
    using IterableSet for IterableSet.Set;

    Board public board;
    address public manager;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;

    // TODO: set this somewhere
    uint public minimumTerm;

    // Tokens that this fund is approved to own.
    // TODO: Make this effectively public with view functions.
    IterableSet.Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denominatingAsset;
    
    // TODO: Make this effectively public with view functions.
    IterableSet.Set members;

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) public memberTimeLock;

    // U9 - View a funds name
    // The name of the fund
    string public fundName;

    struct JoinRequest {
        uint unlockTime;
        uint initialContribution;
        uint expectedContribution;
    }

    mapping(address => JoinRequest) requests;
    //
    // events
    //

    // todo: more thought on this & actual use
    event Withdraw(address indexed user, uint indexed amount);
    event ApproveToken(address indexed ERC20Token);
    event RemoveToken(address indexed ERC20Token);
    event newJoinRequest(address indexed from);

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

    constructor()
      public
    {
        revert("Unimplimented");
    }

    function setManager(address newManager) 
        external
        onlyBoard
    {
        manager = newManager;
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

    // TODO: Add some structure for managing requests.
    // U4 - Join a new fund
    function joinFund(uint lockupPeriod, uint initialContribution, uint expectedShares)
        public
        onlyNotMember
    {
        require(lockupPeriod >= minimumTerm, "Your lockup period is not long enough");
        emit newJoinRequest(msg.sender);
        requests[msg.sender] = JoinRequest(lockupPeriod, initialContribution, expectedShares);
    }


    // U6 - Must make a contribution to a fund if already a member
    function makeContribution()
        public
        onlyMember
    {
        revert("Unimplimented");
    }

    // U18 - Withdraw from a fund if my timelock has expired
    function withdrawBenefits()
        public
        onlyMember
        timelockExpired
    {
        revert("Unimplimented");
    }

    function withdrawFees()
        public
        onlyManager
    {
        revert("Unimplimented");
    }

    function executeRequest()
        public
        onlyManager
    {
        revert("Unimplimented");
    }
    
    function cancelRequest()
        public
        onlyManager
    {
        revert("Unimplimented");
    }

    function balanceOfToken()
        public
        view
        returns (uint)
    {
        revert("Unimplimented");
    }

    function fundBalances()
        public
        view
        returns (uint[])
    {
        revert("Unimplimented");
    }

}
