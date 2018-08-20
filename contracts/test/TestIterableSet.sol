pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "../utils/IterableSet.sol";

contract TestIterableSet {
    using IterableSet for IterableSet.Set;

    IterableSet.Set set;

    function indices(address a)
        public
        view
        returns (uint)
    {
        return set.indices[a];
    }

    function items(uint i)
        public
        view
        returns (address)
    {
        return set.items[i];
    }

    function itemsLength()
        public
        view
        returns (uint)
    {
        return set.items.length;
    }

    function initialise()
        public
    {
        set.initialise();
    }

    function isInitialised()
        public
        view
        returns (bool)
    {
        return set.isInitialised();
    }

    function size()
        public
        view
        returns (uint)
    {
        return set.size();
    }

    function contains(address a)
        public
        view
        returns (bool)
    {
        return set.contains(a);
    }

    function get(uint i)
        public
        view
        returns (address)
    {
        return set.get(i);
    }

    function add(address a)
        public
        returns (bool)
    {
        return set.add(a);
    }

    function remove(address a)
        public 
        returns (bool)
    {
        return set.remove(a);
    }

    function pop()
        public
        returns (address)
    {   
        return set.pop();
    }
}