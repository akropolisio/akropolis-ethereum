pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

library IterableSet {
    using IterableSet for IterableSet.Set;

    struct Set {
        mapping(address => uint) indices;
        address[] items;
    }

    modifier mustBeInitialised(Set storage s) {
        require(s.isInitialised(), "Set is uninitialised.");
        _;
    }

    function initialiseSet(Set storage s)
        internal
    {
        require(!s.isInitialised(), "Set must be uninitialised.");
        s.items.push(address(0));
    }

    function isInitialised(Set storage s)
        internal
        view
        returns (bool)
    {
        return s.items.length != 0 && s.items[0] == 0;
    }

    function size(Set storage s)
        internal
        view
        mustBeInitialised(s)
        returns (uint)
    {
        return s.items.length - 1;
    }

    function contains(Set storage s, address a)
        internal
        view
        mustBeInitialised(s)
        returns (bool)
    {
        return s.indices[a] != 0;
    }

    function get(Set storage s, uint i)
        internal
        view
        mustBeInitialised(s)
        returns (address)
    {
        require(i < s.items.length - 1, "Set index out of range.");
        return s.items[i + 1];
    }

    function add(Set storage s, address a)
        internal
        mustBeInitialised(s)
        returns (bool)
    {
        if (s.contains(a)) {
            return false;
        }
        s.indices[a] = s.items.length;
        s.items.push(a);
        return true;
    }

    function remove(Set storage s, address a)
        internal
        mustBeInitialised(s)
        returns (bool)
    {
        if (s.contains(a)) {
            // Find the index of `k` and swap it with the last item, remove last item
            uint newLength = s.items.length - 1;
            s.items[s.indices[a]] = s.items[newLength]; 
            delete s.items[newLength];
            s.items.length--;
            delete s.indices[a];
            return true;
        }
        return false;
    }

    function pop(Set storage s)
        internal
        mustBeInitialised(s)
        returns (address)
    {   
        uint len = s.items.length - 1;
        require(len > 1, "Cannot pop from empty Set.");
        address item = s.items[len];
        delete s.items[len];
        delete s.indices[item];
        return item;
    }
}