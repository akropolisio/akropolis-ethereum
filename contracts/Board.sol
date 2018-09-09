pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./utils/IterableSet.sol";
import "./utils/BytesHandler.sol";
import "./interfaces/ERC20Token.sol";
import "./AkropolisFund.sol";

contract Board is BytesHandler {
    using IterableSet for IterableSet.Set;

    enum MotionType {
        SetFund,
        AddDirectors,
        RemoveDirectors,
        SetManager,
        SetManagementFee,
        SetMinimumTerm,
        SetDenominatingAsset,
        ResetTimeLock,
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

    function _getMotion(uint motionID)
        internal
        view
        returns (Motion storage)
    {
        require(motionID < motions.length, "Invalid motion ID.");
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
        uint id = _pushMotion(motionType, MotionStatus.Active, msg.sender,
                              duration, 0, 0, description, data);
        emit MotionInitiated(id);
        return id;
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
        require(motion.status == MotionStatus.Passed, "Motion must pass to be executed.");

        if (_motionPastExpiry(motion)) {
            _expireMotion(motion);
            return false;
        }

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
        } else if (motionType == MotionType.SetManagementFee) {
            result = _executeSetManagementFee(data);
        } else if (motionType == MotionType.SetMinimumTerm) {
            result = _executeSetMinimumTerm(data);
        } else if (motionType == MotionType.SetDenominatingAsset) {
            result = _executeSetDenominatingAsset(data);
        } else if (motionType == MotionType.ResetTimeLock) {
            result = _executeResetTimeLock(data);
        } else if (motionType == MotionType.ApproveTokens) {
            result = _executeApproveTokens(data);
        } else if (motionType == MotionType.DisapproveTokens) {
            result = _executeDisapproveTokens(data);
        } else {
            revert("Unsupported motion type (this should be impossible).");
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
        uint dataLength = data.length;
        for (uint i; i < dataLength; i += ADDRESS_BYTES) {
            address director = _extractAddress(data, i);
            if (directors.add(director)) {
                emit DirectorAdded(director);
            }
        }
        return true;
    }

    function _executeRemoveDirectors(bytes data)
        internal
        returns (bool)
    {
        uint dataLength = data.length;
        for (uint i; i < dataLength; i += ADDRESS_BYTES) {
            address director = _extractAddress(data, i);
            if (directors.remove(director)) {
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

    function _executeSetMinimumTerm(bytes data)
        internal
        returns (bool)
    {
        return fund.setMinimumTerm(_extractUint(data, 0));
    }

    function _executeSetDenominatingAsset(bytes data)
        internal
        returns (bool)
    {
        return fund.setDenominatingAsset(ERC20Token(_extractAddress(data, 0)));
    }

    function _executeResetTimeLock(bytes data)
        internal
        returns (bool)
    {
        return fund.resetTimeLock(_extractAddress(data, 0));
    }

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
    }

    function cancelMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getActiveMotion(motionID);
        require(msg.sender == motion.initiator, "Only the initiator may cancel a motion.");
        require(motion.votesFor + motion.votesAgainst == 0, "Motions with non-abstention votes cannot be cancelled.");
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
    }

    function _expireMotion(Motion storage motion)
        internal
    {
        require(_motionPastExpiry(motion), "Motion has not expired.");
        motion.status = MotionStatus.Expired;
        emit MotionExpired(motion.id);
    }

    function expireMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getVotableMotion(motionID);
        _expireMotion(motion);
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
    {
        Motion storage motion = _getVotableMotion(motionID);

        if (_motionPastExpiry(motion)) {
            _expireMotion(motion);
            return;
        }

        VoteType existingVote = motion.vote[msg.sender];
        if (existingVote == VoteType.Yes) {
            return;
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
    }

    function voteAgainstMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getVotableMotion(motionID);

        if (_motionPastExpiry(motion)) {
            _expireMotion(motion);
            return;
        }

        VoteType existingVote = motion.vote[msg.sender];
        if (existingVote == VoteType.No) {
            return;
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
    }

    function abstainFromMotion(uint motionID)
        public
        onlyDirectors
    {
        Motion storage motion = _getVotableMotion(motionID);

        if (_motionPastExpiry(motion)) {
            _expireMotion(motion);
            return;
        }

        VoteType existingVote = motion.vote[msg.sender];
        motion.vote[msg.sender] = VoteType.Abstain;
        if (existingVote == VoteType.Abstain ||
            existingVote == VoteType.Absent) {
            return;
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
}
