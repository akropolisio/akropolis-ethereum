pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


library AddressSet {
    using AddressSet for AddressSet.Set;

    struct Set {
        mapping(address => uint) indices;
        address[] items;
    }

    modifier assertInitialised(Set storage s) {
        require(s.isInitialised(), "Set uninitialised.");
        _;
    }

    function initialise(Set storage s)
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
        return s.items.length != 0;
    }

    function destroy(Set storage s)
        internal
        assertInitialised(s)
    {
        uint length = s.items.length;

        for (uint i; i < length; i++) {
            delete s.indices[s.items[i]];
            delete s.items[i];
        }

        s.items.length = 0;
    }

    function size(Set storage s)
        internal
        view
        assertInitialised(s)
        returns (uint)
    {
        return s.items.length - 1;
    }

    function contains(Set storage s, address a)
        internal
        view
        assertInitialised(s)
        returns (bool)
    {
        return s.indices[a] != 0;
    }

    function get(Set storage s, uint i)
        internal
        view
        assertInitialised(s)
        returns (address)
    {
        uint index = i + 1;
        require(index < s.items.length, "Index out of range.");
        return s.items[index];
    }

    function array(Set storage s)
        internal
        view
        assertInitialised(s)
        returns (address[])
    {
        address[] memory itemlist = new address[](s.items.length - 1);
        for (uint i = 1; i < s.items.length; i++) {
            itemlist[i-1] = s.items[i];
        }
        return itemlist;
    }

    function add(Set storage s, address a)
        internal
        assertInitialised(s)
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
        assertInitialised(s)
        returns (bool)
    {
        if (s.contains(a)) {
            uint newLength = s.items.length - 1;
            address swappee = s.items[newLength];
            uint oldIndex = s.indices[a];

            // Overwrite the removed item with the last one, then shrink the list.
            s.items[oldIndex] = swappee;
            s.indices[swappee] = oldIndex;
            delete s.items[newLength];
            s.items.length--;
            delete s.indices[a];

            return true;
        }
        return false;
    }

    function pop(Set storage s)
        internal
        assertInitialised(s)
        returns (address)
    {   
        uint len = s.items.length - 1;
        require(len > 0, "Popped empty set.");
        address item = s.items[len];

        delete s.items[len];
        delete s.indices[item];
        s.items.length--;

        return item;
    }
}
