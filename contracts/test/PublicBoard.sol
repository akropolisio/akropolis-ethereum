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
        _pushMotion(motionType, status, msg.sender,
                    duration, votesFor, votesAgainst,
                    description, data);
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

    function getVotableMotion(uint motionID)
        public
        view
        returns (uint)
    {
        return _getVotableMotion(motionID).id;
    }

    function setFund(AkropolisFund _fund)
        public
    {
        fund = _fund;
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

    function executeSetManagementFee(bytes data)
        public
        returns (bool)
    {
        return _executeSetManagementFee(data);
    }

    function executeResetTimeLock(bytes data)
        public
        returns (bool)
    {
        return _executeResetTimeLock(data);
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
