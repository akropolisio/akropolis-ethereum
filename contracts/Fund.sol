pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./utils/SafeDecimalMath.sol";

// All fixed point math is done to 18 decimal places.
contract AkropolisFund is SafeDecimalMath {
    address board; // TODO: This should be of type Board, once we merge in the `board-of-directors` branch.
    address manager;

    uint managementFee;
    // Percentage of profits per time?
    // Is it a percentage of AUM?
    // Per something else? Is it a flat rate?
    // TODO: Confirm these details with ana.

    ERC20Token[] approvedTokens;
}