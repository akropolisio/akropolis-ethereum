pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Unimplemented.sol";

// The fund itself should have non-transferrable shares which represent share in the fund.
contract AkropolisFund is PensionFund, Unimplemented {
    using IterableSet for IterableSet.Set;

    address public board; // TODO: This should be of type Board, once we merge in the `board-of-directors` branch.
    address public manager;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;

    // Tokens that this fund is approved to own.
    // TODO: Make this effectively public with view functions.
    IterableSet.Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denominatingAsset;
    
    // TODO: Make this effectively public with view functions.
    IterableSet.Set members;

    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) public memberTimeLock;

    modifier onlyBoard() {
        require(msg.sender == board, "Sender is not the Board of Directors.");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == board, "Sender is not the manager.");
        _;
    }

    constructor()
      public
    {
        unimplemented();
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
    function joinFund()
        public
    {
        unimplemented();
    }

    function makeContribution()
        public
    {
        unimplemented();
    }

    function withdrawBenefits()
        public
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
