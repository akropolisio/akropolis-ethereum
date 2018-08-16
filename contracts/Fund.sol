pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";

// All fixed point math is done to 18 decimal places.
contract AkropolisFund is IterableSet {
    address board; // TODO: This should be of type Board, once we merge in the `board-of-directors` branch.
    address manager;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint managementFeePerYear;

    // Tokens that this fund is approved to own.
    Set approvedTokens;

    // Token in which benefits will be paid.
    ERC20Token quoteAsset;
    
    // Each user has a time after which they can withdraw benefits. Can be modified by fund directors.
    mapping(address => uint) userTimeLock;

    Set members;

}
