pragma solidity ^0.4.24;
pragma experimental "v0.5.0";


import "../Board.sol";


contract PublicBoard is Board {
    constructor(address[] initialDirectors)
        Board(initialDirectors)
        public
    {}

    function pushMotion(MotionType motionType, MotionStatus status, uint duration,
                        uint votesFor, uint votesAgainst, string description, bytes data)
        public
        returns (uint)
    {
        uint id = motions.length;

        motions.push(Motion(
            id,
            motionType,
            status,
            msg.sender,
            now + duration,
            votesFor, votesAgainst,
            description,
            data));

        return id;
    }

    function getMotion(uint motionID)
        public
        view
        returns (uint)
    {
        return _getMotion(motionID).id;
    }

    function getActiveMotion(uint motionID)
        public
        view
        returns (uint)
    {
        return _getActiveMotion(motionID).id;
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