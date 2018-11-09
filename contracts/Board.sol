<<<<<<< HEAD
<<<<<<< HEAD
pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
=======
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
pragma solidity ^0.4.23;
// TODO: Add licence header and file description info.
// TODO: Natural specification.
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

import "./utils/Set.sol";
import "./utils/BytesHandler.sol";
<<<<<<< HEAD
<<<<<<< HEAD
import "./interfaces/ERC20Token.sol";
import "./AkropolisFund.sol";

contract Board is BytesHandler {
    using AddressSet for AddressSet.Set;
=======
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
import "./interfaces/PensionFund.sol";

contract Board is BytesHandler {
    using IterableSet for IterableSet.Set;
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

    enum MotionType {
        SetFund,
        AddDirectors,
        RemoveDirectors,
        SetManager,
        SetContributionManager,
        SetManagementFee,
        SetMinimumLockupDuration,
        SetMinimumPayoutDuration,
        SetDenomination,
        ResetTimeLock,
        SetRecomputationDelay,
        ApproveTokens,
        DisapproveTokens
    }

    enum VoteType {
        Absent,
        Yes,
        No
    }

    enum MotionStatus {
        Cancelled,
        Active,
        Executed,
        Failed,
        ExecutionFailed,
        Expired
    }

    struct Motion {
        uint id;
        MotionType motionType;
        MotionStatus status;
<<<<<<< HEAD
<<<<<<< HEAD
        address initiator;
        uint timestamp;
=======
        address creator;
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
        address creator;
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
        uint expiry;
        uint votesFor;
        uint votesAgainst;
        string description;
        bytes data;
        mapping(address => VoteType) vote; // Default value is "Absent"
    }

    modifier onlyDirectors() {
        require(isDirector(msg.sender), "Not director.");
        _;
    }

<<<<<<< HEAD
<<<<<<< HEAD
    AddressSet.Set _directors;
    Motion[] public motions;
    AkropolisFund public fund;
=======
    IterableSet.Set directors;
    Motion[] motions;
    PensionFund fund;
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    IterableSet.Set directors;
    Motion[] motions;
    PensionFund fund;
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

    constructor (address[] initialDirectors)
        public
    {
<<<<<<< HEAD
<<<<<<< HEAD
        _directors.initialise();
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
        uint len = initialDirectors.length;
        // If no directors were given, the sender is the first director.
        if (len == 0) {
            _directors.add(msg.sender);
        } else {
            for (uint i; i < len; i++) {
                _directors.add(initialDirectors[i]);
            }
        }
    }

    function unimplimented() 
        internal
        pure
    {
        revert("Unimplimented.");
    }

    function isDirector(address director)
        public
        view
        returns (bool)
    {
        return _directors.contains(director);
    }

    function numDirectors()
        public
        view
        returns (uint)
    {
        return _directors.size();
    }

    function getDirector(uint i)
        public
        view
        returns (address)
    {
        return _directors.get(i);
    }

    function getDirectors()
        public
        view
        returns (address[])
    {
        return _directors.array();
    }

    function resignAsDirector()
        public
        onlyDirectors
    {
        require(_directors.size() > 1, "Sole director cannot resign.");
        _directors.remove(msg.sender);
        emit Resigned(msg.sender);
        emit DirectorRemoved(msg.sender);
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

<<<<<<< HEAD
    function _getMotion(uint motionID)
=======
    function getActiveMotion(uint motionID)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
        internal
        view
        returns (Motion storage)
    {
        require(motionID < motions.length, "Invalid ID.");
        return motions[motionID];
    }

    function getActiveMotion(uint motionID)
        internal
        view
        returns (Motion storage)
    {
        Motion storage motion = _getMotion(motionID);
        require(motion.status == MotionStatus.Active, "Motion inactive.");
        return motion;
    }

<<<<<<< HEAD
<<<<<<< HEAD
    function _isVotable(MotionStatus status)
=======
    function isValidMotionType(MotionType motionType)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    function isValidMotionType(MotionType motionType)
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
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
        require(_isVotable(status), "Motion not votable.");
        require(!_motionPastExpiry(motion), "Motion expired.");
        return motion;
    }

    /// @return ID of the initiated motion.
    function initiateMotion(MotionType motionType, uint duration, string description, bytes data)
        public
        onlyDirectors
        returns (uint)
    {
<<<<<<< HEAD
        require(data.length > 0, "No data.");
        require(bytes(description).length > 0, "No description.");
        uint id = _pushMotion(motionType, MotionStatus.Active, msg.sender,
                              duration, 0, 0, description, data);
        emit MotionInitiated(id);
        return id;
    }
=======
        // TODO: Add a test to ensure this thing throws if motionType not in range.
        // TODO: Test that motion type ends up mapping to the appropriate motion type.
        // TODO: Test that duration is properly set for all motion types.

        require(isValidMotionType(motionType), "Invalid motion type.");
        require(data.length > 0, "Data must not be empty.");
        uint numMotions = motions.length;
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

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
        Motion storage motion = _getVotableMotion(motionID);

        require(motion.status == MotionStatus.Passed, "Motion hasn't passed.");

        bytes storage data = motion.data;
        MotionType motionType = motion.motionType;
        bool result;

        if (motionType == MotionType.SetFund) {
            result = _executeSetFund(data);
        } else if (motionType == MotionType.SetManager) {
            result = _executeSetManager(data);
        } else if (motionType == MotionType.SetContributionManager) {
            result = _executeSetContributionManager(data);
        } else if (motionType == MotionType.AddDirectors) {
            result = _executeAddDirectors(data);
        } else if (motionType == MotionType.RemoveDirectors) {
            result = _executeRemoveDirectors(data);
        } else if (motionType == MotionType.SetManagementFee) {
            result = _executeSetManagementFee(data);
        } else if (motionType == MotionType.SetMinimumLockupDuration) {
            result = _executeSetMinimumLockupDuration(data);
        } else if (motionType == MotionType.SetMinimumPayoutDuration) {
            result = _executeSetMinimumPayoutDuration(data);
        } else if (motionType == MotionType.SetDenomination) {
            result = _executeSetDenomination(data);
        } else if (motionType == MotionType.ResetTimeLock) {
            result = _executeResetTimeLock(data);
        } else if (motionType == MotionType.SetRecomputationDelay) {
            result = _executeSetRecomputationDelay(data);
        } else if (motionType == MotionType.ApproveTokens) {
            result = _executeApproveTokens(data);
        } else if (motionType == MotionType.DisapproveTokens) {
            result = _executeDisapproveTokens(data);
        } else {
            revert("Paradox: unknown motion type.");
        }

        if (result) {
            motion.status = MotionStatus.Executed;
            emit MotionExecuted(motionID);
        } else {
            motion.status = MotionStatus.ExecutionFailed;
            emit MotionExecutionFailed(motionID);
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

    function executeSetManager(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

<<<<<<< HEAD
<<<<<<< HEAD
    function _executeSetContributionManager(bytes data)
        internal
        returns (bool)
    {
        return fund.setContributionManager(_extractAddress(data, 0));
=======
    function executeSetManager(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    }

    function executeAddDirectors(bytes data)
        internal
        returns (bool)
    {
<<<<<<< HEAD
        uint dataLength = data.length;
        for (uint i; i < dataLength; i += ADDRESS_BYTES) {
            address director = _extractAddress(data, i);
            if (_directors.add(director)) {
                emit DirectorAdded(director);
            }
        }
        return true;
=======
    function executeAddDirectors(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    }

    /// @return ID of the initiated motion.
    function executeRemoveDirectors(bytes data)
        internal
        returns (bool)
    {
<<<<<<< HEAD
        uint dataLength = data.length;
        for (uint i; i < dataLength; i += ADDRESS_BYTES) {
            address director = _extractAddress(data, i);
            if (_directors.remove(director)) {
                emit DirectorRemoved(director);
            }
        }
        return true;
    }

    function _executeSetManagementFee(bytes data)
        internal
        returns (bool)
    {
        return fund.setManagementFee(_extractUint(data, 0));
    }

    function _executeSetMinimumLockupDuration(bytes data)
        internal
        returns (bool)
    {
        return fund.setMinimumLockupDuration(_extractUint(data, 0));
    }

    function _executeSetMinimumPayoutDuration(bytes data)
        internal
        returns (bool)
    {
        return fund.setMinimumPayoutDuration(_extractUint(data, 0));
    }

    function _executeSetDenomination(bytes data)
        internal
        returns (bool)
    {
        return fund.setDenomination(ERC20Token(_extractAddress(data, 0)));
    }

    function _executeResetTimeLock(bytes data)
        internal
        returns (bool)
    {
        return fund.resetTimeLock(_extractAddress(data, 0));
    }
=======
        unimplimented();
    }

    function executeSetFee(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

    function executeSetTimeLock(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

    function executeApproveTokens(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

=======
        unimplimented();
    }

    /// @return ID of the initiated motion.
    function executeRemoveDirectors(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

    function executeSetFee(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

    function executeSetTimeLock(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

    function executeApproveTokens(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    function executeDisapproveTokens(bytes data)
        internal
        returns (bool)
    {
        unimplimented();
    }

    function executeMotion(uint motionID)
        internal
<<<<<<< HEAD
    {
        Motion storage motion = getActiveMotion(motionID);
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

    function _executeSetRecomputationDelay(bytes data)
        internal
        returns (bool)
    {
        return fund.setRecomputationDelay(_extractUint(data, 0));
    }
=======
    {
        Motion storage motion = getActiveMotion(motionID);
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

<<<<<<< HEAD
    function _executeApproveTokens(bytes data)
        internal
        returns (bool)
    {
        uint numTokens = data.length / ADDRESS_BYTES;
        ERC20Token[] memory tokens = new ERC20Token[](numTokens);
        for (uint i; i < numTokens; i++) {
            tokens[i] = ERC20Token(_extractAddress(data, i*ADDRESS_BYTES));
        }
        return fund.approveTokens(tokens);
    }

    function _executeDisapproveTokens(bytes data)
        internal
        returns (bool)
    {
        uint numTokens = data.length / ADDRESS_BYTES;
        ERC20Token[] memory tokens = new ERC20Token[](numTokens);
        for (uint i; i < numTokens; i++) {
            tokens[i] = ERC20Token(_extractAddress(data, i*ADDRESS_BYTES));
        }
        return fund.disapproveTokens(tokens);
=======
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
<<<<<<< HEAD
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    }

    function cancelMotion(uint motionID)
        public
        onlyDirectors
    {
<<<<<<< HEAD
<<<<<<< HEAD
        Motion storage motion = _getActiveMotion(motionID);
        require(msg.sender == motion.initiator, "Not initiator.");
        require(motion.votesFor + motion.votesAgainst == 0, "Motion has votes.");
        motion.status = MotionStatus.Cancelled;
        emit MotionCancelled(motionID);
    }

    function _motionPastExpiry(Motion storage motion)
        internal
        view
        returns (bool)
    {
        return motion.expiry < now;
    }

    function motionPastExpiry(uint motionID)
        public
        view
        returns (bool)
    {
        Motion storage motion = _getMotion(motionID);
        return _motionPastExpiry(motion);
=======
        unimplimented();
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
        unimplimented();
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    }

    function expireMotion(uint motionID)
        public
<<<<<<< HEAD
<<<<<<< HEAD
        onlyDirectors
    {
        Motion storage motion = _getMotion(motionID);
        require(_motionPastExpiry(motion), "Motion not expired.");
        motion.status = MotionStatus.Expired;
        emit MotionExpired(motion.id);
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
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    {
        unimplimented();
    }

<<<<<<< HEAD
<<<<<<< HEAD
    function _motionPasses(Motion storage motion)
        internal
        view
        returns (bool)
    {
        return motion.votesFor > _directors.size() / 2;
    }

    function _motionFails(Motion storage motion)
        internal
        view
        returns (bool)
    {
        return motion.votesAgainst >= _directors.size() / 2;
    }
=======
    function votePasses(motion )
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    function votePasses(motion )
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund

    function voteForMotion(uint motionID)
        public
        onlyDirectors
<<<<<<< HEAD
<<<<<<< HEAD
        returns (uint votesFor, uint votesAgainst)
    {
        Motion storage motion = _getVotableMotion(motionID);

        VoteType existingVote = motion.vote[msg.sender];
        if (existingVote == VoteType.Yes) {
            return (motion.votesFor, motion.votesAgainst);
        }

        motion.vote[msg.sender] = VoteType.Yes;
        motion.votesFor++;
        if (existingVote == VoteType.No) {
            motion.votesAgainst--;
        }

        emit VoteCast(motionID, msg.sender, VoteType.Yes);

        if (_motionPasses(motion)) {
            motion.status = MotionStatus.Passed;
        }

        return (motion.votesFor, motion.votesAgainst);
=======
    {
        Motion storage motion = getActiveMotion(motionID);
        unimplimented();

>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    {
        Motion storage motion = getActiveMotion(motionID);
        unimplimented();

>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    }

    function voteAgainstMotion(uint motionID)
        public
        onlyDirectors
<<<<<<< HEAD
<<<<<<< HEAD
        returns (uint votesFor, uint votesAgainst)
    {
        Motion storage motion = _getVotableMotion(motionID);

        VoteType existingVote = motion.vote[msg.sender];
        if (existingVote == VoteType.No) {
            return (motion.votesFor, motion.votesAgainst);
        }

        motion.vote[msg.sender] = VoteType.No;
        motion.votesAgainst++;
        if (existingVote == VoteType.Yes) {
            motion.votesFor--;
        }
        emit VoteCast(motionID, msg.sender, VoteType.No);

        if (_motionFails(motion)) {
            motion.status = MotionStatus.Failed;
        }

        return (motion.votesFor, motion.votesAgainst);
=======
    {
        Motion storage motion = getActiveMotion(motionID);
        unimplimented();
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
    {
        Motion storage motion = getActiveMotion(motionID);
        unimplimented();
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
    }

    function abstainFromMotion(uint motionID)
        public
        onlyDirectors
<<<<<<< HEAD
<<<<<<< HEAD
        returns (uint votesFor, uint votesAgainst)
    {
        Motion storage motion = _getVotableMotion(motionID);

        VoteType existingVote = motion.vote[msg.sender];
        motion.vote[msg.sender] = VoteType.Abstain;
        if (existingVote == VoteType.Abstain ||
            existingVote == VoteType.Absent) {
            return (motion.votesFor, motion.votesAgainst);
        }

        if (existingVote == VoteType.Yes) {
            motion.votesFor--;
        } else if (existingVote == VoteType.No) {
            motion.votesAgainst--;
        }
        emit VoteCast(motionID, msg.sender, VoteType.Abstain);

        if (!(_motionPasses(motion) || _motionFails(motion))) {
            motion.status = MotionStatus.Active;
        }

        return (motion.votesFor, motion.votesAgainst);
    }

    event Resigned(address indexed director);
    event DirectorRemoved(address indexed director);
    event DirectorAdded(address indexed director);
    event MotionInitiated(uint indexed motionID);
    event VoteCast(uint indexed motionID, address indexed director, VoteType indexed vote);
    event MotionExecuted(uint indexed motionID);
    event MotionExecutionFailed(uint indexed motionID);
    event MotionCancelled(uint indexed motionID);
    event MotionExpired(uint indexed motionID);
    event SetFund(address indexed fund);
}
=======
    {
=======
    {
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
        Motion storage motion = getActiveMotion(motionID);
        unimplimented();
    }
    

<<<<<<< HEAD
}
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
=======
}
>>>>>>> parent of c666e5e... Merge branch 'board-of-directors' into join-fund
