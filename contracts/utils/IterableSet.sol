pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

library IterableSet {

    struct Set {
        mapping(address => uint) indices;
        address[] items;
    }

    function initialiseSet(Set storage s)
        internal
    {
        s.items.push(address(0));
    }

    function contains(Set storage s, address a)
        internal
        view
        returns (bool)
    {
        return s.indices[a] != 0;
    }

    function get(Set storage s, address a)
        internal
        view
        returns (address)
    {
        return s.items[s.indices[a]];
    }

    function add(Set storage s, address a)
        internal
        returns (bool)
    {
        uint index = s.indices[a];
        if (index == 0) {
            return true;
        } else {
            s.indices[a] = s.items.length;
            s.items.push(a);
            return false;
        }
    }

    function remove(Set storage s, address a)
        internal
        returns (bool)
    {
        uint index = s.indices[a];
        if (index == 0) {
            return false;
        }
        // Find the index of `k` and swap it with the last item, remove last item
        s.items[index] = s.items[s.items.length - 1]; 
        delete s.items[s.items.length - 1];
        s.items.length--;
        return true;
    }
}