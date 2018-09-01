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

    function setManagementFee(uint fee) 
        external
        returns (bool)
    {
        emit SetManagementFee(fee);
        return true;
    }

    function setMinimumTerm(uint term)
        external
        returns (bool)
    {
        emit SetMinimumTerm(term);
        return true;
    }

    function setDenominatingAsset(address token)
        external
        returns (bool)
    {
        emit SetDenominatingAsset(token);
        return true;
    }

    function resetTimeLock(address user)
        external
        returns (bool)
    {
        emit ResetTimeLock(user);
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
    event SetManagementFee(uint indexed fee);
    event SetMinimumTerm(uint indexed term);
    event SetDenominatingAsset(address indexed token);
    event ResetTimeLock(address indexed user);
    event ApproveTokens(ERC20Token[] tokens);
    event DisapproveTokens(ERC20Token[] tokens);
}