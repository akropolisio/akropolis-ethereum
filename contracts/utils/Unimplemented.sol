
pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

contract Unimplemented {
    function unimplemented()
        pure
        internal
    {
        revert("Unimplemented.");
    }
}
