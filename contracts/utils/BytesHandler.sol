pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


contract BytesHandler {

    // TODO: Investigate if these are made more efficient by direct CALLDATA extraction.

<<<<<<< HEAD
<<<<<<< HEAD
    uint constant UINT_BYTES = 32;
    uint constant ADDRESS_BYTES = 20;

    function _extractUint(bytes b, uint offset)
=======
    function getUint(bytes b, uint offset)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    function getUint(bytes b, uint offset)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
        pure
        internal
        returns (uint)
    {
        bytes32 result;
        for (uint i; i < UINT_BYTES; i++) {
            result |= bytes32(b[offset + i]) >> (i * 8);
        }
        return uint(result);
    }

<<<<<<< HEAD
<<<<<<< HEAD
    function _extractUints(bytes b, uint n, uint offset)
        pure
        internal
        returns (uint[])
    {
        uint[] memory numbers = new uint[](n);

        for (uint i; i < n; i++) {
            numbers[i] = _extractUint(b, offset + i*UINT_BYTES);
        }
        return numbers;
    }

    function _extractAddress(bytes b, uint offset)
=======
    function getAddress(bytes b, uint offset)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    function getAddress(bytes b, uint offset)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
        pure
        internal
        returns (address)
    {
        bytes20 result;
        for (uint i; i < ADDRESS_BYTES; i++) {
            result |= bytes20(b[offset + i]) >> (i * 8);
        }
        return address(result);
    }

    function _extractAddresses(bytes b, uint n, uint offset)
        pure
        internal
        returns (address[])
    {
        address[] memory addresses = new address[](n);

        for (uint i; i < n; i++) {
            addresses[i] = _extractAddress(b, offset + i*ADDRESS_BYTES);
        }
        return addresses;
    }

}
