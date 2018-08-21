pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

contract Clock {
    function currentTime()
        public
        view
        returns (uint)
    {
        return now;
    }
}