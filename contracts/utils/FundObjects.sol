pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "../interfaces/ERC20Token.sol";

// Abstract contract
contract FundObjects {

    struct JoinRequest {
        uint unlockTime;
        ERC20Token[] tokens;
        uint[] contributions;
        uint expectedShares;
        bool pending;
    }
}