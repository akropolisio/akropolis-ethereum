pragma solidity ^0.4.23;
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
import "./interfaces/PensionFund.sol";

contract Board is BytesHandler {
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
        Yes,
        No
    }

    enum MotionStatus {
        Active,
        Cancelled,
        Executed,
        Failed,
        ExecutionFailed,
        Expired
    }

    struct Motion {
        uint id;
        MotionType motionType;
        MotionStatus motionStatus;
        address creator;
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
    Motion[] motions;
    PensionFund fund;

    // TODO: Write tests for this:
    //       * all directors are properly initialised.
    //       * if no directors provided then the sender is the first director.
    // TODO: Should charge AKT tokens.
    constructor (address[] initialDirectors)
        public
    {
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

    function isValidMotionType(MotionType motionType)
        internal
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

        require(isValidMotionType(motionType), "Invalid motion type.");
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

    function executeMotion(uint motionID)
        internal
    {
        require(motionID < motions.length, "Invalid motion ID");

        Motion storage motion = motions[motionID];
        require(motion.status == MotionStatus.Active, "Motion is inactive.");

        bytes storage data = motion.data;
        MotionType motionType = motion.motionType;
        bool result;

        if (motionType == MotionType.SetManager) {
            result = executeSetManager(data);
        } else if (motionType == MotionType.AddDirectors) {
            result = executeAddDirectors(data);
        } else if (motionType == MotionType.RemoveDirectors) {
            result = executeRemoveDirectors(data);
        } else if (motionType == MotionType.SetFee) {
            result = executeSetFee(data);
        } else if (motionType == MotionType.SetTimeLock) {
            result = executeSetTimeLock(data);
        } else if (motionType == MotionType.ApproveTokens) {
            result = executeApproveTokens(data);
        } else if (motionType == MotionType.DisapproveTokens) {
            result = executeDisapproveTokens(data);
        } else {
            // TODO: Verify that this error string is correctly returned.
            revert("Unsupported motion type.");
        }
    }

    function cancelMotion(uint motionID)
        public
        onlyDirectors
    {
        revert("Unimplimented function.");
    }

    function expireMotion(uint motionID)
        public
    {
        revert("Unimplimented function.");
    }

    function executeSetManager(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.

        revert("Unimplimented motion type.");
    }

    function executeAddDirectors(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    /// @return ID of the initiated motion.
    function executeRemoveDirectors(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    function executeSetFee(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    function executeSetTimeLock(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    function executeApproveTokens(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    function executeDisapproveTokens(bytes data)
        internal
        returns (bool)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }
}