pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./utils/Owned.sol";
import "./AkropolisFund.sol";
import "./utils/IterableSet.sol";
import "./interfaces/ERC20Token.sol";

// Composes a one-to-many relation; a group may contain many tokens,
// but a token may be in only one group. A group is represented by an address.
// Later, these addresses might be actual contracts with functionality themselves.
contract Group {}

contract FundGovernor is Owned {
    using IterableSet for IterableSet.Set;

    struct TokenGroups {
        address withdrawalGroup;
        address depositGroup;
    }

    AkropolisFund fund;

    address constant LOCKDOWN = address(0); // Disallows all actions.
    address constant UNGOVERNED = address(~uint(0)); // Allows all actions.
    address constant DEXES = address(1); // Addresses in this group are decentralised exchanges.

    mapping(address => TokenGroups) public tokenGroup; // The group a token is a member of.

    mapping(address => IterableSet) public groupMembers; // The addresses contained by a group.

    constructor(AkropolisFund _fund,
                address initialOwner)
        Owned(initialOwner)
        public
    {
        fund = _fund;
    }

    function setFund(AkropolisFund newFund)
        onlyOwner
        external
    {
        fund = newFund;
    }

    function addToGroup(ERC20Token token, Group group)
        onlyOwner
        external
    {
        tokenGroups[token].add(group);
        groupMembers[group].add(token);
    }

    function removeFromGroup(ERC20Token token, Group group)
        onlyOwner
        external
    {
        tokenGroups[token].add(group);
        groupMembers[group].remove(token);
    }

    function withdrawalAllowed(ERC20Token token, uint quantity, address destination)
        public
        returns (bool)
    {
        Group storage groups = tokenGroups[token];

        if (groups.contains(LOCKDOWN)) {
            return false;
        } else if (groups.contains(UNGOVERNED)) {
            return true;
        }

    }

    function approvalAllowed(ERC20Token token, uint quantity, address destination)
        public
        returns (bool)
    {
        IterableSet storage groups = tokenGroups[token];

        if (groups.contains(LOCKDOWN)) {
            return false;
        } else if (groups.contains(UNGOVERNED)) {
            return true;
        }
    }

    function depositAllowed(ERC20Token token, uint quantity, address destination)
        public
        returns (bool)
    {
        return false;
    }
}
