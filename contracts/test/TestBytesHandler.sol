pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


import "../utils/BytesHandler.sol";


contract TestBytesHandler is BytesHandler {
    function extractUint(bytes b, uint offset)
        pure
        public
        returns (uint)
    {
        return _extractUint(b, offset);
    }

    function extractAddress(bytes b, uint offset)
        pure
        public
        returns (address)
    {
        return _extractAddress(b, offset);
    }
}