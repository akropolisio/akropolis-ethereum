/*
* The MIT License
*
* Copyright (c) 2017-2018 , Akropolis Decentralised Ltd (Gibraltar), http://akropolis.io
*
*/

pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


import "../utils/BytesHandler.sol";


contract PublicBytesHandler is BytesHandler {
    function extractUint(bytes b, uint offset)
        pure
        public
        returns (uint)
    {
        return _extractUint(b, offset);
    }

    function extractUints(bytes b, uint n, uint offset)
        pure
        public
        returns (uint[])
    {
        return _extractUints(b, n, offset);
    }

    function extractAddress(bytes b, uint offset)
        pure
        public
        returns (address)
    {
        return _extractAddress(b, offset);
    }

    function extractAddresses(bytes b, uint n, uint offset)
        pure
        public
        returns (address[])
    {
        return _extractAddresses(b, n, offset);
    }
}
