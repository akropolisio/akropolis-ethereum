pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


import "../Board.sol";


contract TestBoard is Board {
    function getActiveMotion(uint motionID)
        public
        view
        returns (uint)
    {
        return _getActiveMotion(motionID).id;
    }

    function isValidMotionType(MotionType motionType)
        pure
        public
        returns (bool)
    {
        return _isValidMotionType(motionType);
    }

    function executeSetManager(bytes data)
        public
        returns (bool)
    {
        return _executeSetManager(data);
    }

    function executeAddDirectors(bytes data)
        public
        returns (bool)
    {
        return _executeAddDirectors(data);
    }

    function executeRemoveDirectors(bytes data)
        public
        returns (bool)
    {
        return _executeRemoveDirectors(data);
    }

    function executeSetFee(bytes data)
        public
        returns (bool)
    {
        return _executeSetFee(data);
    }

    function executeSetTimeLock(bytes data)
        public
        returns (bool)
    {
        return _executeSetTimeLock(data);
    }

    function executeApproveTokens(bytes data)
        public
        returns (bool)
    {
        return _executeApproveTokens(data);
    }

    function executeDisapproveTokens(bytes data)
        public
        returns (bool)
    {
        return _executeDisapproveTokens(data);
    }

}