pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
// TODO: Add licence header and file description info.
// TODO: Natural specification.

/***
DEV:

User stories to be implemented for the board of directors:

MUST HAVE:

D1: Create a board of directors contract; 
    * Initial set of directors is configurable.
    * Deployment charges AKT fees.

D2: Initiate a new motion. Motions should contain:
    * Type
    * Expiry Time
    * Vote tallies
    * Extra data

D3: Vote to change the fund manager.


SHOULD HAVE:

D4: Vote to add directors
D5: Vote to remove directors
D6: Vote to set fee rate


COULD HAVE:

D7: Nullify an investor's time lock (lower quorum requirement?)
D8: Add approved investible token
D9: Remove approved investible token

***/

import "./utils/IterableSet.sol";
import "./utils/BytesHandler.sol";
import "./utils/Unimplemented.sol";
import "./interfaces/PensionFund.sol";

contract Board is BytesHandler, Unimplemented {
    using IterableSet for IterableSet.Set;

    enum MotionType {
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
        uint expiry;
        uint votesFor;
        uint votesAgainst;
        string description;
        bytes data;
        mapping(address => VoteType) vote; // Default value is "Absent"
        // TODO: Add a test verifying the default value to enforce the ordering of VoteType enum.
    }

    modifier onlyDirectors() {
        require(isDirector(msg.sender), "Caller is not a director.");
        _;
    }

    IterableSet.Set directors;
    Motion[] public motions;
    PensionFund public fund;

    // TODO: Write tests for this:
    //       * all directors are properly initialised.
    //       * if no directors provided then the sender is the first director.
    // TODO: Should charge AKT tokens.
    constructor (address[] initialDirectors)
        public
    {
        directors.initialiseSet();
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

    function resignAsDirector()
        public
        onlyDirectors
    {
        require(directors.size() > 1, "Sole director cannot resign.");
        directors.remove(msg.sender);
    }

    function _getActiveMotion(uint motionID)
        internal
        view
        returns (Motion storage)
    {
        require(motionID < motions.length, "Invalid motion ID");
        Motion storage motion = motions[motionID];
        require(motion.status == MotionStatus.Active, "Motion is inactive.");
        return motion;
    }

    function _isValidMotionType(MotionType motionType)
        pure
        internal
        returns (bool)
    {
        return motionType == MotionType.SetManager ||
               motionType == MotionType.AddDirectors ||
               motionType == MotionType.RemoveDirectors ||
               motionType == MotionType.SetFee ||
               motionType == MotionType.SetTimeLock ||
               motionType == MotionType.ApproveTokens ||
               motionType == MotionType.DisapproveTokens;
    }

    /// @return ID of the initiated motion.
    function initiateMotion(MotionType motionType, uint duration, string description, bytes data)
        public
        onlyDirectors
        returns (uint)
    {
        // TODO: Add a test to ensure this thing throws if motionType not in range.
        // TODO: Test that motion type ends up mapping to the appropriate motion type.
        // TODO: Test that duration is properly set for all motion types.

        require(_isValidMotionType(motionType), "Invalid motion type.");
        require(data.length > 0, "Data must not be empty.");
        uint numMotions = motions.length;

        motions.push(Motion(
            numMotions,
            motionType,
            MotionStatus.Active,
            msg.sender,
            now + duration,
            0, 0,
            description,
            data));

        // TODO: Test that the returned id is actually the proper last id.
        return numMotions;
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
        unimplemented();
    }

    function _executeRemoveDirectors(bytes data)
        internal
        returns (bool)
    {
        unimplemented();
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

    function executeMotion(uint motionID)
        public
        onlyDirectors
        returns (bool)
    {
        Motion storage motion = _getActiveMotion(motionID);

        bytes storage data = motion.data;
        MotionType motionType = motion.motionType;
        bool result;

        if (motionType == MotionType.SetManager) {
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
            // TODO: Verify that this reverts correctly.
            revert("Unsupported motion type.");
        }

        if (result) {
            motion.status = MotionStatus.Executed;
        } else {
            motion.status = MotionStatus.ExecutionFailed;
        }

        return result;
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

    function expireMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getActiveMotion(motionID);
        require(motion.expiry < now, "Motion has not expired.");
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
        Motion storage motion = _getActiveMotion(motionID);
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
        Motion storage motion = _getActiveMotion(motionID);
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
        Motion storage motion = _getActiveMotion(motionID);
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
}