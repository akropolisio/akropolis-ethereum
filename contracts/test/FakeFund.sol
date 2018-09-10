pragma solidity ^0.4.24;

import "../interfaces/ERC20Token.sol";

contract FakeFund {

    function setManager(address manager) 
        external
        returns (bool)
    {
        emit SetManager(manager);
        return true;
    }

    function setManagementFeeRatePerYear(uint fee)
        external
        returns (bool)
    {
        emit SetManagementFeeRatePerYear(fee);
        return true;
    }

    function setMinimumLockupDuration(uint term)
        external
        returns (bool)
    {
        emit SetMinimumLockupDuration(term);
        return true;
    }

    function setMinimumPayoutDuration(uint term)
        external
        returns (bool)
    {
        emit SetMinimumPayoutDuration(term);
        return true;
    }

    function setDenomination(address token)
        external
        returns (bool)
    {
        emit SetDenomination(token);
        return true;
    }

    function resetTimeLock(address user)
        external
        returns (bool)
    {
        emit ResetTimeLock(user);
        return true;
    }

    function setRecomputationDelay(uint delay)
        external
        returns (bool)
    {
        emit SetRecomputationDelay(delay);
        return true;
    }

    function approveTokens(ERC20Token[] tokens)
        external
        returns (bool)
    {
        emit ApproveTokens(tokens);
        return true;
    }

    function disapproveTokens(ERC20Token[] tokens)
        external
        returns (bool)
    {
        emit DisapproveTokens(tokens);
        return true;
    }

    event SetManager(address indexed manager);
    event SetManagementFeeRatePerYear(uint indexed fee);
    event SetMinimumLockupDuration(uint indexed term);
    event SetMinimumPayoutDuration(uint indexed term);
    event SetDenomination(address indexed token);
    event ResetTimeLock(address indexed user);
    event SetRecomputationDelay(uint indexed delay);
    event ApproveTokens(ERC20Token[] tokens);
    event DisapproveTokens(ERC20Token[] tokens);
}
