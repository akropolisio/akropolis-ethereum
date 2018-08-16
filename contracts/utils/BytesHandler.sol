pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


contract BytesHandler {
    function getUint(bytes b, uint offset)
        pure
        internal
        returns (uint)
    {
        bytes32 result;
        for (uint i; i < 32; i++) {
            result |= bytes32(b[offset + i]) >> (i * 8);
        }
        return uint(result);
    }

    function getAddress(bytes b, uint offset)
        pure
        internal
        returns (address)
    {
        bytes20 result;
        for (uint i; i < 20; i++) {
            result |= bytes20(b[offset + i]) >> (i * 8);
        }
        return address(result);
    }
}