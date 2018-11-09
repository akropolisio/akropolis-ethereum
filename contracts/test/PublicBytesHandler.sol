pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


import "../utils/BytesHandler.sol";


<<<<<<< HEAD:contracts/test/PublicBytesHandler.sol
contract PublicBytesHandler is BytesHandler {
    function extractUint(bytes b, uint offset)
=======
contract TestBytesHandler is BytesHandler {
    function _getUint(bytes b, uint offset)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund:contracts/test/TestBytesHandler.sol
        pure
        public
        returns (uint)
    {
        return getUint(b, offset);
    }

<<<<<<< HEAD:contracts/test/PublicBytesHandler.sol
    function extractUints(bytes b, uint n, uint offset)
        pure
        public
        returns (uint[])
    {
        return _extractUints(b, n, offset);
    }

    function extractAddress(bytes b, uint offset)
=======
    function _getAddress(bytes b, uint offset)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund:contracts/test/TestBytesHandler.sol
        pure
        public
        returns (address)
    {
        return getAddress(b, offset);
    }

    function extractAddresses(bytes b, uint n, uint offset)
        pure
        public
        returns (address[])
    {
        return _extractAddresses(b, n, offset);
    }
}
