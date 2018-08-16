pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


import "../utils/BytesHandler.sol";


contract TestBytesHandler is BytesHandler {
    function _getUint(bytes b, uint offset)
        pure
        public
        returns (uint)
    {
        return getUint(b, offset);
    }

    function _getAddress(bytes b, uint offset)
        pure
        internal
        returns (address)
    {
        return getAddress(b, offset);
    }
}