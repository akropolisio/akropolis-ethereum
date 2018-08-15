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

contract Board {

    enum MotionType {
        ChangeFundManager,
        AddDirectors,
        RemoveDirectors
    }

    enum VoteType {
        Absent,
        Yes,
        No
    }

    struct Motion {
        uint id;
        MotionType motionType;
        uint expiry;
        uint votesFor;
        uint votesAgainst;
        mapping(address => VoteType) vote; // Default value is "Absent"
        // TODO: Add a test verifying the default value to enforce the ordering of VoteType enum.
        bytes data;
    }

    modifier onlyDirectors() {
        require(isDirector[msg.sender], "Caller is not a director.");
        _;
    }

    mapping(address => bool) isDirector;
    address[] directors;
    Motion[] motions;

    // TODO: Write tests for this:
    //       * all directors are properly initialised.
    //       * if no directors provided then the sender is the first director.
    // TODO: Should charge AKT tokens.
    constructor (address[] initialDirectors)
        public
    {
        uint len = initialDirectors.length;

        // If no directors were specified,
        // then the contract creator becomes the first director.
        if (len == 0) {
            _addDirector(msg.sender);
        } else {
            for (uint i; i < len; i++) {
                _addDirector(initialDirectors[i]);
            }
        }
    }

    // TODO: Test that this works properly
    function _addDirector(address director)
        internal
    {
        isDirector[director] = true;
        directors.push(director);
    }

    /// @return ID of the initiated motion.
    function initiateMotion(MotionType motionType, uint duration, bytes data)
        public
        onlyDirectors
        returns (uint)
    {
        // TODO: Add a test to ensure this thing throws if motionType not in range.
        // TODO: Test that motion type ends up mapping to the appropriate motion type.
        // TODO: Test that duration is properly set for all motion types.

        uint id;
        if (motionType == MotionType.ChangeFundManager) {
            id = _initiateChangeFundManager(data);
        } else if (motionType == MotionType.AddDirectors) {
            id = _initiateAddDirectors(data);
        } else if (motionType == MotionType.RemoveDirectors) {
            id = _initiateRemoveDirectors(data);
        } else {
            // TODO: Verify that this error string is correctly returned.
            revert("Unsupported motion type.");
        }

        // TODO: Test that the returned id is actually the proper last id.
        return id;
    }

    /// @return ID of the initiated motion.
    function _initiateChangeFundManager(bytes data)
        internal
        returns (uint)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    /// @return ID of the initiated motion.
    function _initiateAddDirectors(bytes data)
        internal
        returns (uint)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

    /// @return ID of the initiated motion.
    function _initiateRemoveDirectors(bytes data)
        internal
        returns (uint)
    {
        // TODO: Test unimplimented throws properly.
        revert("Unimplimented motion type.");
    }

}