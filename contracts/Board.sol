pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./utils/IterableSet.sol";
import "./utils/BytesHandler.sol";
import "./utils/Unimplemented.sol";
import "./AkropolisFund.sol";

contract Board is BytesHandler, Unimplemented {
    using IterableSet for IterableSet.Set;

    enum MotionType {
        SetFund,
        SetManager,
        AddDirectors,
        RemoveDirectors,
        SetFee,
        SetTimeLock,
        ApproveTokens,
        DisapproveTokens
    }

    enum VoteType {
        Absent,
        Abstain,
        Yes,
        No
    }

    /*
     * Motions are created in the Active state.
     * Available transitions:
     *      Active -> Expired   (time passes)
     *      Active -> Cancelled (initiator cancels motion)
     *      Active -> Failed    (enough directors vote against)
     *      Active -> Passed    (enough directors vote in favour)
     *      Passed -> Executed  (execution function is called)
     *      Passed -> ExecutionFailed ( :( )
     */
    enum MotionStatus {
        Cancelled,
        Active,
        Passed,
        Failed,
        Executed,
        ExecutionFailed,
        Expired
    }

    struct Motion {
        uint id;
        MotionType motionType;
        MotionStatus status;
        address initiator;
        uint timestamp;
        uint expiry;
        uint votesFor;
        uint votesAgainst;
        string description;
        bytes data;
        mapping(address => VoteType) vote; // Default value is "Absent"
    }

    modifier onlyDirectors() {
        require(isDirector(msg.sender), "Caller is not a director.");
        _;
    }

    IterableSet.Set directors;
    Motion[] public motions;
    AkropolisFund public fund;

    constructor (address[] initialDirectors)
        public
    {
        directors.initialise();
        uint len = initialDirectors.length;
        // If no directors were given, the sender is the first director.
        if (len == 0) {
            directors.add(msg.sender);
        } else {
            for (uint i; i < len; i++) {
                directors.add(initialDirectors[i]);
            }
        }
    }

    function isDirector(address director)
        public
        view
        returns (bool)
    {
        return directors.contains(director);
    }

    function numDirectors()
        public
        view
        returns (uint)
    {
        return directors.size();
    }

    function getDirector(uint i)
        public
        view
        returns (address)
    {
        return directors.get(i);
    }

    function getDirectors()
        public
        view
        returns (address[])
    {
        return directors.itemList();
    }

    function resignAsDirector()
        public
        onlyDirectors
    {
        require(directors.size() > 1, "Sole director cannot resign.");
        directors.remove(msg.sender);
    }

    function numMotions()
        public
        view
        returns (uint)
    {
        return motions.length;
    }

    function motionVote(uint motionID, address director)
        public
        view
        returns (VoteType)
    {
        Motion storage motion = _getMotion(motionID);
        return motion.vote[director];
    }

    function _getMotion(uint motionID)
        internal
        view
        returns (Motion storage)
    {
        require(motionID < motions.length, "Invalid motion ID");
        return motions[motionID];
    }

    function _getActiveMotion(uint motionID)
        internal
        view
        returns (Motion storage)
    {
        Motion storage motion = _getMotion(motionID);
        require(motion.status == MotionStatus.Active, "Motion is inactive.");
        return motion;
    }

    function _isVotable(MotionStatus status) 
        internal
        pure
        returns (bool)
    {
        return status == MotionStatus.Active ||
               status == MotionStatus.Failed ||
               status == MotionStatus.Passed;
    }

    function _getVotableMotion(uint motionID)
        internal
        view
        returns (Motion storage)
    {
        Motion storage motion = _getMotion(motionID);
        MotionStatus status = motion.status;
        require(_isVotable(status), "Motion cannot be voted upon.");
        return motion;
    }

    /// @return ID of the initiated motion.
    function initiateMotion(MotionType motionType, uint duration, string description, bytes data)
        public
        onlyDirectors
        returns (uint)
    {
        require(data.length > 0, "Data must not be empty.");
        return _pushMotion(motionType, MotionStatus.Active, msg.sender,
                           duration, 0, 0, description, data);
    }

    function _pushMotion(MotionType motionType, MotionStatus status,
                         address initiator, uint duration,
                         uint votesFor, uint votesAgainst,
                         string description, bytes data)
        internal
        returns (uint)
    {
        uint id = motions.length;
        motions.push(Motion(
            id,
            motionType,
            status,
            initiator,
            now,
            now + duration,
            votesFor, votesAgainst,
            description,
            data));
        return id;
    }

    function executeMotion(uint motionID)
        public
        onlyDirectors
        returns (bool)
    {
        Motion storage motion = _getMotion(motionID);
        require(motion.status == MotionStatus.Passed, "Motions must pass to be executed.");

        bytes storage data = motion.data;
        MotionType motionType = motion.motionType;
        bool result;

        if (motionType == MotionType.SetFund) {
            result = _executeSetFund(data);
        } else if (motionType == MotionType.SetManager) {
            result = _executeSetManager(data);
        } else if (motionType == MotionType.AddDirectors) {
            result = _executeAddDirectors(data);
        } else if (motionType == MotionType.RemoveDirectors) {
            result = _executeRemoveDirectors(data);
        } else if (motionType == MotionType.SetFee) {
            result = _executeSetFee(data);
        } else if (motionType == MotionType.SetTimeLock) {
            result = _executeSetTimeLock(data);
        } else if (motionType == MotionType.ApproveTokens) {
            result = _executeApproveTokens(data);
        } else if (motionType == MotionType.DisapproveTokens) {
            result = _executeDisapproveTokens(data);
        } else {
            revert("Unsupported motion type (this should be impossible).");
        }

        if (result) {
            motion.status = MotionStatus.Executed;
        } else {
            motion.status = MotionStatus.ExecutionFailed;
        }

        return result;
    }

    function _executeSetFund(bytes data)
        internal
        returns (bool)
    {
        address fundAddress = _extractAddress(data, 0);
        fund = AkropolisFund(fundAddress);
        emit SetFund(fundAddress);
        return true;
    }

    function _executeSetManager(bytes data)
        internal
        returns (bool)
    {
        return fund.setManager(_extractAddress(data, 0));
    }

    function _executeAddDirectors(bytes data)
        internal
        returns (bool)
    {
        for (uint i = 0; i < data.length; i += ADDRESS_BYTES) {
            directors.add(_extractAddress(data, i));
        }
        return true;
    }

    function _executeRemoveDirectors(bytes data)
        internal
        returns (bool)
    {
        for (uint i = 0; i < data.length; i += ADDRESS_BYTES) {
            directors.remove(_extractAddress(data, i));
        }
        return true;
    }

    function _executeSetFee(bytes data)
        internal
        returns (bool)
    {
        unimplemented();
    }

    function _executeSetTimeLock(bytes data)
        internal
        returns (bool)
    {
        unimplemented();
    }

    function _executeApproveTokens(bytes data)
        internal
        returns (bool)
    {
        unimplemented();
    }

    function _executeDisapproveTokens(bytes data)
        internal
        returns (bool)
    {
        unimplemented();
    }

    function cancelMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getActiveMotion(motionID);
        require(msg.sender == motion.initiator, "Only the initiator may cancel a motion.");
        require(motion.votesFor + motion.votesAgainst == 0, "Motions with non-abstention votes cannot be cancelled.");
        motion.status = MotionStatus.Cancelled;
    }

    function motionPastExpiry(uint motionID) 
        public
        view
        returns (bool)
    {
        Motion storage motion = _getMotion(motionID);
        return motion.expiry < now;
    }

    function expireMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getVotableMotion(motionID);
        require(motionPastExpiry(motionID), "Motion has not expired.");
        motion.status = MotionStatus.Expired;
    }

    function motionPasses(uint motionID) 
        public
        view
        returns (bool)
    {
        return _motionPasses(_getActiveMotion(motionID));
    }

    function motionFails(uint motionID) 
        public
        view
        returns (bool)
    {
        return _motionFails(_getActiveMotion(motionID));
    }


    function _motionPasses(Motion storage motion)
        internal
        view
        returns (bool)
    {
        return motion.votesFor > directors.size() / 2;
    }

    function _motionFails(Motion storage motion)
        internal
        view
        returns (bool)
    {
        return motion.votesAgainst >= directors.size() / 2;
    }

    function voteForMotion(uint motionID)
        public
        onlyDirectors
        returns (bool)
    {
        Motion storage motion = _getVotableMotion(motionID);

        if (motionPastExpiry(motionID)) {
            motion.status = MotionStatus.Expired;
            return true;
        }

        VoteType existingVote = motion.vote[msg.sender];

        if (existingVote == VoteType.Yes) {
            return false;
        }

        motion.vote[msg.sender] = VoteType.Yes;
        motion.votesFor++;
        if (existingVote == VoteType.No) {
            motion.votesAgainst--;
        }

        if (_motionPasses(motion)) {
            motion.status = MotionStatus.Passed;
            return true;
        }
        return false;
    }

    function voteAgainstMotion(uint motionID)
        public
        onlyDirectors
        returns (bool)
    {
        Motion storage motion = _getVotableMotion(motionID);

        if (motionPastExpiry(motionID)) {
            motion.status = MotionStatus.Expired;
            return true;
        }

        VoteType existingVote = motion.vote[msg.sender];

        if (existingVote == VoteType.No) {
            return false;
        }

        motion.vote[msg.sender] = VoteType.No;
        motion.votesAgainst++;
        if (existingVote == VoteType.Yes) {
            motion.votesFor--;
        }

        if (_motionFails(motion)) {
            motion.status = MotionStatus.Failed;
            return true;
        }
        return false;
    }

    function abstainFromMotion(uint motionID)
        public
        onlyDirectors
        returns (bool)
    {
        Motion storage motion = _getVotableMotion(motionID);

        if (motionPastExpiry(motionID)) {
            motion.status = MotionStatus.Expired;
            return true;
        }

        VoteType existingVote = motion.vote[msg.sender];

        if (existingVote == VoteType.Abstain) {
            return false;
        }

        motion.vote[msg.sender] = VoteType.Abstain;

        if (existingVote == VoteType.Absent) {
            return false;
        }

        if (existingVote == VoteType.Yes) {
            bool passed = _motionPasses(motion);
            motion.votesFor--;
            return passed && !_motionPasses(motion);
        }

        bool failed = _motionFails(motion);
        motion.votesAgainst--;
        return failed && !_motionFails(motion);
    }


    event SetFund(address indexed fund);
}
