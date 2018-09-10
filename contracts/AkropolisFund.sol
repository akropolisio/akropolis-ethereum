pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./Board.sol";
import "./Ticker.sol";
import "./NontransferableShare.sol";
import "./Registry.sol";
import "./interfaces/PensionFund.sol";
import "./interfaces/ERC20Token.sol";
import "./utils/IterableSet.sol";
import "./utils/Unimplemented.sol";
import "./utils/Owned.sol";

contract AkropolisFund is Owned, PensionFund, NontransferableShare, Unimplemented {
    using IterableSet for IterableSet.Set;

    // The pension fund manger
    address public manager;

    // An address that can trigger recurring contributions.
    address public contributionManager;

    // The ticker to source price data from
    Ticker public ticker;
    
    // The registry that the fund will be shown on
    Registry public registry;

    // Percentage of AUM over one year.
    // TODO: Add a flat rate as well. Maybe also performance fees.
    uint public managementFeePerYear;

    // Users may not join unless they satisfy these minima. 
    uint public minimumLockupDuration;
    uint public minimumPayoutDuration;

    // Tokens that this fund is approved to own.
    IterableSet.Set _approvedTokens;

    // Tokens with nonzero balances.
    // These are tracked for more-efficient computation of gross fund value.
    IterableSet.Set _ownedTokens;

    // Token in which benefits will be paid.
    ERC20Token public denomination;
    uint public denominationDecimals;

    // The set of members of this fund and their details.
    IterableSet.Set _members;
    mapping(address => MemberDetails) public memberDetails;

    // Candidate member join requests.
    mapping(address => MembershipRequest) public membershipRequests;

    // Member historic contributions.
    mapping(address => Contribution[]) public contributions;

    // The addresses permitted to set up a contribution schedule for a given beneficiary.
    mapping(address => IterableSet.Set) _permittedContributors;
    // Active contribution schedules. The signature here is (beneficiary => contributor => schedule).
    mapping(address => mapping(address => RecurringContributionSchedule)) public contributionSchedule;

    // Members can grant the manager permission to directly withdraw.
    // Ordinarily, they are not permitted to pull deposits from member accounts,
    // which may have granted ERC-20 approvals due to recurring payments.
    // Type: member => token => quantity.
    mapping(address => mapping(address => uint)) public managerDebitAllowance;

    // Historic record of actions taken by the fund manager.
    LogEntry[] public managementLog;

    // The frequency at which the fund recomputes its value.
    uint public recomputationDelay = 0;

    // Historic price values.
    FundValue[] public fundValues;

    //
    // structs
    //

    struct MembershipRequest {
        uint timestamp;
        uint lockupDuration;
        uint payoutDuration;
        bool setupSchedule;
        uint scheduledContribution;
        uint scheduleDelay;
        uint scheduleDuration;
        uint initialContribution;
        uint expectedShares;
        bool pending;
    }

    struct Contribution {
        address contributor;
        uint timestamp;
        ERC20Token token;
        uint quantity;
    }

    struct RecurringContributionSchedule {
        ERC20Token token;
        uint contributionQuantity;
        uint contributionDelay; // TODO: Rename to periodLength
        uint terminationTime;
        uint previousContributionTime;
    }

    // Each member has a time after which they can withdraw benefits. Can be modified by fund directors.
    // In addition they have a payment frequency, and the fund may make withdrawals of 
    // a given quantity from the member's account at no greater than the specified frequency.
    struct MemberDetails {
        uint joinTime;
        uint unlockTime;
        uint finalBenefitTime;
        uint totalUnlockable;
    }

    enum LogType {
        Withdrawal,
        Deposit,
        Approval
    }

    struct LogEntry {
        LogType logType;
        uint timestamp;
        ERC20Token token;
        uint quantity;
        address account;
        uint code;
        string annotation;
    }

    struct FundValue {
        uint value;
        uint timestamp;
    }

    event Withdraw(address indexed member, uint indexed amount);
    event ApproveToken(address indexed ERC20Token);
    event RemoveToken(address indexed ERC20Token);
    event newMembershipRequest(address indexed from);
    event newMemberAccepted(address indexed member);

    modifier onlyBoard {
        require(msg.sender == address(board()), "Not board.");
        _;
    }

    modifier onlyRegistry {
        require(msg.sender == address(registry), "Not registry.");
        _;
    }

    modifier onlyManager {
        require(msg.sender == manager, "Not manager.");
        _;
    }

    modifier onlyMember(address account) {
        require(_members.contains(account), "Not member.");
        _;
    }

    modifier onlyNotMember(address account) {
        require(!_members.contains(account), "Already member.");
        _;
    }

    modifier noPendingJoin(address account) {
        MembershipRequest memory request = membershipRequests[account];
        require(!request.pending, "Request exists.");
        _;
    }

    modifier onlyApprovedToken(address token) {
        require(_approvedTokens.contains(token), "Token not approved.");
        _;
    }

    modifier onlyDenomination(ERC20Token token) {
        require(token == denomination, "Token not fund denomination.");
        _;
    }

    modifier postRecordFundValueIfTime {
        _;
        _recordFundValueIfTime();
    }

    constructor(
        Board _board,
        Ticker _ticker,
        Registry _registry,
        uint _managementFeePerYear,
        uint _minimumLockupDuration,
        uint _minimumPayoutDuration,
        ERC20Token _denomination,
        string _name,
        string _symbol
    )
        Owned(_board) // The board is the owner of this contract.
        NontransferableShare(_name, _symbol) // Internal shares are managed as a non-transferrable ERC20 token
        public
    {
        registry = _registry;
        managementFeePerYear = _managementFeePerYear;
        minimumLockupDuration = _minimumLockupDuration;
        minimumPayoutDuration = _minimumPayoutDuration;

        // All sets must first be initialised before they are used.
        _members.initialise();
        _approvedTokens.initialise();
        _ownedTokens.initialise();

        // By default the denominating asset is an approved investible token.
        denomination = _denomination;
        denominationDecimals = _denomination.decimals();
        _approvedTokens.add(_denomination);

        // Ticker records the fund value so that functions that rely upon
        // obtaining the last fund valuation do not break.
        // This must occur after the previous sets have been initialised.
        ticker = _ticker;
        _recordFundValue();

        // Register the fund on the registry, msg.sender pays for it in AKT.
        registry.addFund(msg.sender);
    }

    function setManager(address newManager) 
        external
        onlyBoard
        returns (bool)
    {
        registry.updateManager(manager, newManager);
        manager = newManager;
        return true;
    }

    function setContributionManager(address newContributionManager) 
        external
        onlyBoard
        returns (bool)
    {
        contributionManager = newContributionManager;
        return true;
    }

    function nominateNewBoard(Board newBoard)
        external
        onlyBoard
        returns (bool)
    {
        nominateNewOwner(address(newBoard));
        return true;
    }

    function setManagementFee(uint newFee)
        external
        onlyBoard
        returns (bool)
    {
        managementFeePerYear = newFee;
        return true;
    }

    function setMinimumLockupDuration(uint newLockupDuration)
        external
        onlyBoard
        returns (bool)
    {
        minimumLockupDuration = newLockupDuration;
        return true;
    }

    function setMinimumPayoutDuration(uint newPayoutDuration)
        external
        onlyBoard
        returns (bool)
    {
        minimumPayoutDuration = newPayoutDuration;
        return true;
    }

    function setRecomputationDelay(uint delay)
        external
        onlyBoard
        returns (bool)
    {
        recomputationDelay = delay;
        return true;
    }

    function setDenomination(ERC20Token token)
        external
        onlyBoard
        returns (bool)
    {
        _approvedTokens.remove(denomination);
        _approvedTokens.add(token);
        denomination = token;
        denominationDecimals = token.decimals();
        return true;
    }

    function setRegistry(Registry _registry)
        external
        onlyRegistry
    {
        registry = _registry;
    }


    // The board can only unlock someone's lock so that they
    // can withdraw everything. A more robust system would allow
    // a user to propose a modification to their payment schedule.
    function resetTimeLock(address member)
        external
        onlyBoard
        onlyMember(member)
        returns (bool)
    {
        memberDetails[member].unlockTime = now;
        memberDetails[member].finalBenefitTime = now;
        return true;
    }

    function approveTokens(ERC20Token[] tokens)
      external
      onlyBoard
      returns (bool)
    {
        for (uint i; i < tokens.length; i++) {
            _approvedTokens.add(address(tokens[i]));
        }
        return true;
    }

    function disapproveTokens(ERC20Token[] tokens)
      external
      onlyBoard
      returns (bool)
    {
        for (uint i; i < tokens.length; i++) {
            _approvedTokens.remove(address(tokens[i]));
        }
        return true;
    }

    function isApprovedToken(address token) 
        external
        view
        returns (bool)
    {
        return _approvedTokens.contains(token);
    }

    function numApprovedTokens()
        external
        view
        returns (uint)
    {
        return _approvedTokens.size();
    }

    function approvedToken(uint i)
        external
        view
        returns (address)
    {
        return _approvedTokens.get(i);
    }
    
    function approvedTokens()
        external
        view
        returns (address[])
    {
        return _approvedTokens.array();
    }

    function isOwnedToken(address token) 
        external
        view
        returns (bool)
    {
        return _ownedTokens.contains(token);
    }

    function numOwnedTokens()
        external
        view
        returns (uint)
    {
        return _ownedTokens.size();
    }

    function ownedToken(uint i)
        external
        view
        returns (address)
    {
        return _ownedTokens.get(i);
    }
    
    function ownedTokens()
        external
        view
        returns (address[])
    {
        return _ownedTokens.array();
    }


    function isMember(address account)
        external
        view
        returns (bool)
    {
        return _members.contains(account);
    }

    function numMembers()
        external
        view
        returns (uint)
    {
        return _members.size();
    }

    function getMember(uint i)
        external
        view
        returns (address)
    {
        return _members.get(i);
    }

    function board()
        public
        view
        returns (Board)
    {
        return Board(owner);
    }

    function managementLogLength()
        public
        view
        returns (uint)
    {
        return managementLog.length;
    }

    function unlockTime(address member)
        public
        view
        returns (uint)
    {
        return memberDetails[member].unlockTime;
    }

    function joinTime(address member)
        public
        view
        returns (uint)
    {
        return memberDetails[member].joinTime;
    }

    function permittedContributors(address member)
        public
        view
        returns (address[])
    {
        return _permittedContributors[member].array();
    }

    function getContributor(address member, uint index)
        public
        view
        returns (address)
    {
        return _permittedContributors[member].get(index);
    }

    function balanceOfToken(ERC20Token token)
        public
        view
        returns (uint)
    {
        return token.balanceOf(this);
    }

    function balanceValueOfToken(ERC20Token token)
        public
        view
        returns (uint)
    {
        return ticker.valueAtRate(token, token.balanceOf(this), denomination);
    }

    function _balances()
        internal
        view
        returns (ERC20Token[] tokens, uint[] tokenBalances)
    {
        uint numTokens = _ownedTokens.size();
        uint[] memory bals = new uint[](numTokens);
        ERC20Token[] memory toks = new ERC20Token[](numTokens);

        for (uint i; i < numTokens; i++) {
            ERC20Token token = ERC20Token(_approvedTokens.get(i));
            bals[i] = token.balanceOf(this);
            toks[i] = token;
        }

        return (toks, bals);
    }

    function balances()
        public
        view
        returns (ERC20Token[] tokens, uint[] tokenBalances)
    {
        return _balances();
    }

    function balanceValues()
        public
        view
        returns (ERC20Token[] tokens, uint[] tokenValues)
    {
        (ERC20Token[] memory toks, uint[] memory bals) = _balances();
        return (toks, ticker.valuesAtRate(toks, bals, denomination));
    }

    function fundValue()
        public
        view
        returns (uint)
    {
        (, uint[] memory vals) = balanceValues();

        uint total;
        for (uint i; i < vals.length; i++) {
            total += vals[i];
        }
        return total;
    }

    function lastFundValue()
        public
        view
        returns (uint value, uint timestamp)
    {
        FundValue storage lastValue = fundValues[fundValues.length-1];
        return (lastValue.value, lastValue.timestamp);
    }

    function _recordFundValue()
        public
        returns (uint)
    {
        uint value = fundValue();
        fundValues.push(FundValue(value, now));
        return value;
    }

    function recordFundValue()
        public
    {
        (, uint timestamp) = lastFundValue();
        require(timestamp < now, "Fund value already recorded.");
        _recordFundValue();
    }

    function _recordFundValueIfTime()
        internal
        returns (uint, bool)
    {
        (uint value, uint timestamp) = lastFundValue();
        if (timestamp <= safeSub(now, recomputationDelay)) {
            return (_recordFundValue(), true);
        }
        return (value, false);
    }

    function _shareValue(uint fundVal)
        internal
        view
        returns (uint)
    {
        uint supply = totalSupply;
        if (supply == 0) {
            return 0;
        }
        uint denomDec = denominationDecimals;
        return safeDiv_mpdec(fundVal, denomDec,
                             supply, decimals,
                             denomDec);
    }

    function shareValue()
        public
        view
        returns (uint)
    {
        return _shareValue(fundValue());
    }

    function lastShareValue()
        public
        view
        returns (uint)
    {
        (uint value, ) = lastFundValue();
        return _shareValue(value);
    }

    function _shareQuantityValue(uint quantity, uint shareVal)
        internal
        view
        returns (uint)
    {
        uint denomDec = denominationDecimals;
        return safeMul_mpdec(shareVal, denomDec,
                             quantity, decimals,
                             denomDec);
    }

    function shareQuantityValue(uint quantity)
        public
        view
        returns (uint)
    {
        return _shareQuantityValue(quantity, shareValue());
    }

    function lastShareQuantityValue(uint quantity)
        public
        view
        returns (uint)
    {
        return _shareQuantityValue(quantity, lastShareValue());
    }

    function shareValueOf(address member)
        public
        view
        returns (uint)
    {
        return shareQuantityValue(balanceOf[member]);
    }

    function lastShareValueOf(address member)
        public
        view
        returns (uint)
    {
        return lastShareQuantityValue(balanceOf[member]);
    }

    function equivalentShares(ERC20Token token, uint tokenQuantity)
        public
        view
        returns (uint)
    {
        if (tokenQuantity == 0) {
            return 0;
        }
        uint tokenVal = ticker.valueAtRate(token, tokenQuantity, denomination);
        uint supply = totalSupply;
        if (supply == 0) {
            // If there are no shares yet, we will hand back a quantity equivalent
            // to the value they provided us.
            return tokenVal;
        }

        (uint fundVal, ) = lastFundValue();

        if (fundVal == 0) {
            return 0; // TODO: Work out what to do in case the fund is worthless.
        }
        uint fractionOfTotal = safeDiv_mpdec(tokenVal, denominationDecimals,
                                             fundVal, denominationDecimals,
                                             denominationDecimals);
        uint fundDecimals = decimals;
        return safeMul_mpdec(supply, fundDecimals,
                             fractionOfTotal, denominationDecimals,
                             fundDecimals);
    }

    // TODO: Allow this to accept arbitrary contribution tokens.
    // They will need to go in the membership request struct and recurring payment object.
    // We may need to add separate structures for determining what tokens members may
    // make contributions in and receive benefits in.
    function requestMembership(address candidate, uint lockupDuration, uint payoutDuration,
                               uint initialContribution, uint expectedShares, bool setupSchedule,
                               uint scheduledContribution, uint scheduleDelay, uint scheduleDuration)
        public
        onlyRegistry
        onlyNotMember(candidate)
        noPendingJoin(candidate)
    {
        require(lockupDuration >= minimumLockupDuration, "Lockup too short.");
        require(payoutDuration >= minimumPayoutDuration, "Payout too short.");
        if (setupSchedule) {
            uint totalDuration = safeAdd(lockupDuration, payoutDuration);
            _validateSchedule(scheduledContribution, scheduleDelay, 0, scheduleDuration, totalDuration);
        }
        require(expectedShares <= equivalentShares(denomination, initialContribution), "Expected too many shares.");

        // Store the request, pending approval.
        membershipRequests[candidate] = MembershipRequest(
            now,
            lockupDuration,
            payoutDuration,
            setupSchedule,
            scheduledContribution,
            scheduleDelay,
            scheduleDuration,
            initialContribution,
            expectedShares,
            true
        );

        // Emit an event now that we've passed all the criteria for submitting a request to join.
        emit newMembershipRequest(candidate);
    }

    function setManagerDebitAllowance(ERC20Token token, uint quantity)
        public
        onlyMember(msg.sender)
    {
        managerDebitAllowance[msg.sender][address(token)] = quantity;
    }

    function _currentSchedulePeriodStartTime(RecurringContributionSchedule storage schedule)
        internal
        view
        returns (uint)
    {
        uint termination = schedule.terminationTime;
        require(now < termination, "Schedule completed.");
        uint periodLength = schedule.contributionDelay;
        uint fullPeriodsToEnd = (termination - now) / periodLength;
        return safeSub(termination, safeMul(fullPeriodsToEnd + 1, periodLength));
    }

    function currentSchedulePeriodStartTime(address member, address contributor)
        public
        view
        returns (uint)
    {
        return _currentSchedulePeriodStartTime(contributionSchedule[member][contributor]);
    }

    function makeRecurringPayment(ERC20Token token, address contributor, address beneficiary, uint expectedShares)
        public
        postRecordFundValueIfTime
    {
        require(msg.sender == contributor ||
                msg.sender == beneficiary ||
                msg.sender == manager ||
                msg.sender == contributionManager,
                "Unauthorised to trigger payment.");

        RecurringContributionSchedule storage schedule = contributionSchedule[beneficiary][contributor];
        uint currentPeriodStartTime = _currentSchedulePeriodStartTime(schedule);
        require(schedule.previousContributionTime <= currentPeriodStartTime,
                "Contribution already made this period.");
        schedule.previousContributionTime = now;

        _contribute(contributor, beneficiary, token,
                    schedule.contributionQuantity, expectedShares,
                    true);
    }

    function permitContributor(address contributor)
        public
        onlyMember(msg.sender)
    {
        _permittedContributors[msg.sender].add(contributor);
    }

    function rejectContributor(address contributor)
        public
        onlyMember(msg.sender)
    {
        _permittedContributors[msg.sender].remove(contributor);
    }

    function _validateSchedule(uint quantity, uint delay, uint startTime, uint terminationTime, uint finalBenefitTime)
        pure
        internal
    {
        require(0 < quantity,
                "Nonzero contribution required.");
        require(startTime < terminationTime && terminationTime <= finalBenefitTime,
                "Schedule must terminate after it begins, before the end of the plan.");
        // The previous require ensures startTime < terminationTime, so that no safeSub is required here.
        require(0 < delay && delay <= terminationTime - startTime,
                "Period length must be nonzero and shorter than schedule.");
    }

    function _setContributionSchedule(address contributor, address beneficiary, ERC20Token token,
                                      uint quantity, uint delay, uint startTime, uint terminationTime)
        internal
        onlyDenomination(token) // TODO: allow contributions in any token, with a more robust contribution permission system.
    {
        require(_permittedContributors[beneficiary].contains(contributor), "Contributor unauthorised.");
        _validateSchedule(quantity, delay, startTime, terminationTime, memberDetails[beneficiary].finalBenefitTime);
        contributionSchedule[beneficiary][contributor] = RecurringContributionSchedule(token, quantity, delay, terminationTime, 0);
    }

    function deleteContributionSchedule(address contributor, address beneficiary)
        external
    {
        require(msg.sender == contributor || msg.sender == beneficiary, "Sender unauthorised.");
        delete contributionSchedule[beneficiary][contributor];
    }

    function setContributionSchedule(address beneficiary, ERC20Token token,
                                     uint quantity, uint delay, uint terminationTime)
        external
    {
        _setContributionSchedule(msg.sender, beneficiary, token, quantity, delay, now, terminationTime);
    }

    function denyMembershipRequest(address candidate)
        public
        onlyManager
    {
        delete membershipRequests[candidate];
        registry.denyMembershipRequest(candidate);
    }

    function cancelMembershipRequest(address candidate)
        public
        onlyRegistry
        onlyNotMember(candidate)
    {
        // This is sent from the registry and already deleted on their end
        delete membershipRequests[candidate];
    }

    function _addOwnedTokenIfBalance(ERC20Token token)
        internal
    {
        if (!_ownedTokens.contains(token)) {
            if(token.balanceOf(this) > 0) {
                _ownedTokens.add(token);
            }
        }
    }

    function _removeOwnedTokenIfNoBalance(ERC20Token token)
        internal
    {
        if (_ownedTokens.contains(token)) {
            if(token.balanceOf(this) == 0) {
                _ownedTokens.remove(token);
            }
        }
    }

    function approveMembershipRequest(address candidate)
        public
        onlyManager
        postRecordFundValueIfTime
    {
        MembershipRequest storage request = membershipRequests[candidate];
        require(request.pending, "Request inactive.");

        // Add them as a member; this must occur before calling _contribute,
        // which enforces that the beneficiary is a member.
        _members.add(candidate);
        uint lockupDuration = request.lockupDuration;
        memberDetails[candidate] = MemberDetails(now,
                                                 now + lockupDuration,
                                                 now + lockupDuration + request.payoutDuration,
                                                 0);
        _permittedContributors[candidate].initialise();
        _permittedContributors[candidate].add(candidate);

        // Set up the candidate's recurring payment schedule if required.
        if (request.setupSchedule) {
            _setContributionSchedule(candidate, candidate, denomination,
                                     request.scheduledContribution,
                                     request.scheduleDelay,
                                     request.timestamp,
                                     now + request.scheduleDuration);
        }

        // Make the actual contribution.
        uint initialContribution = request.initialContribution;
        if (initialContribution > 0) {
            _contribute(candidate, candidate, denomination, initialContribution, request.expectedShares, false);
        }
        
        // Add the candidate to the fund on the registry
        registry.approveMembershipRequest(candidate);

        // Complete the join request.
        membershipRequests[candidate].pending = false;
        emit newMemberAccepted(candidate);
    }

    function _createLockedShares(address beneficiary, uint expectedShares) 
        internal
    {
        _createShares(beneficiary, expectedShares);
        memberDetails[beneficiary].totalUnlockable += expectedShares;
    }
    
    function _contribute(address contributor, address beneficiary, ERC20Token token,
                         uint contribution, uint expectedShares, bool checkShares)
        internal
        onlyMember(beneficiary)
        onlyDenomination(token) // TODO: allow contributions in any token, with a more robust contribution permission system.
    {
        require(now < memberDetails[beneficiary].finalBenefitTime,
                "Plan has terminated.");
        require(_permittedContributors[beneficiary].contains(contributor),
                "Contributor unauthorised.");
        if (checkShares) {
            require(expectedShares <= equivalentShares(token, contribution),
                   "Expected too many shares.");
        }
        require(token.transferFrom(contributor, this, contribution),
                "Token transfer failed.");

        _addOwnedTokenIfBalance(token);
        contributions[beneficiary].push(Contribution(contributor, now, token, contribution));
        _createLockedShares(beneficiary, expectedShares);
    }

    function makeContribution(ERC20Token token, uint contribution, uint expectedShares)
        public
        postRecordFundValueIfTime
    {
        _contribute(msg.sender, msg.sender, token, contribution, expectedShares, true);
    }

    function makeContributionFor(address beneficiary, ERC20Token token, uint contribution, uint expectedShares)
        public
        postRecordFundValueIfTime
    {
        _contribute(msg.sender, beneficiary, token, contribution, expectedShares, true);
    }

    function lockedBenefits(address member)
        public
        view
        returns (uint)
    {
        MemberDetails storage details = memberDetails[member];
        uint totalUnlockable = details.totalUnlockable;
        uint memberUnlockTime = details.unlockTime;
        if (now < memberUnlockTime) {
            return totalUnlockable;
        }

        uint benefitDuration = details.finalBenefitTime - memberUnlockTime;
        if (benefitDuration == 0) {
            return 0;
        }

        uint timeSinceUnlock = now - memberUnlockTime;
        uint dec = decimals;
        uint fractionElapsed = safeDiv_mpdec(intToDec(timeSinceUnlock, dec), dec,
                                             intToDec(benefitDuration, dec), dec,
                                             dec);
        if (fractionElapsed > unit(dec)) {
            return 0;
        }
        return totalUnlockable - safeMul_mpdec(fractionElapsed, dec,
                                               totalUnlockable, dec,
                                               dec);
    }

    function withdrawBenefits(uint shareQuantity)
        public
        onlyMember(msg.sender)
        postRecordFundValueIfTime
        returns (uint)
    {
        uint locked = lockedBenefits(msg.sender);
        uint balance = balanceOf[msg.sender];
        uint destroyableShares = safeSub(balance, locked);
        require(shareQuantity <= destroyableShares, "Insufficient unlockable shares.");
        balanceOf[msg.sender] -= shareQuantity;
        uint value = lastShareQuantityValue(shareQuantity);
        denomination.transfer(msg.sender, value);
        return value;
    }

    function withdrawFees()
        public
        onlyManager
        postRecordFundValueIfTime
    {
        unimplemented();
    }

    // TODO: Make these manager functions two-stage so that, for example, large
    // transfers might require board approval before they go through.
    function withdraw(ERC20Token token, address destination, uint quantity, string annotation)
        external
        onlyManager
        postRecordFundValueIfTime
        returns (uint)
    {
        // TODO: check the Governor if this withdrawal is permitted.
        require(bytes(annotation).length > 0, "No annotation.");
        uint result = token.transfer(destination, quantity) ? 0 : 1;
        _removeOwnedTokenIfNoBalance(token);
        managementLog.push(LogEntry(LogType.Withdrawal, now, token, quantity, destination, result, annotation));
        return result;
    }

    function approveWithdrawal(ERC20Token token, address spender, uint quantity, string annotation)
        external
        onlyManager
        returns (uint)
    {
        return _approveWithdrawal(token, spender, quantity, annotation);
    }

    function approveUserJoiningFees(uint numUsers)
        external
        onlyManager
        returns (uint)
    {
        return _approveWithdrawal(registry.feeToken(), address(registry),
                                  safeMul(registry.userRegistrationFee(), numUsers),
                                  "Membership fee transfers approved.");
    }

    function _approveWithdrawal(ERC20Token token, address spender, uint quantity, string annotation)
        internal
        returns (uint)
    {
        // TODO: check the Governor if this approval is permitted.
        require(bytes(annotation).length > 0, "No annotation.");
        uint result = token.approve(spender, quantity) ? 0 : 1;
        managementLog.push(LogEntry(LogType.Approval, now, token, quantity, spender, result, annotation));
        return result;
    }

    function deposit(ERC20Token token, address depositor, uint quantity, string annotation)
        external
        onlyManager
        onlyApprovedToken(token)
        postRecordFundValueIfTime
        returns (uint)
    {
        // TODO: check the Governor if this deposit is permitted.
        require(bytes(annotation).length > 0, "No annotation.");
        require(!membershipRequests[depositor].pending, "Depositor is candidate member.");
        if (_members.contains(depositor)) {
            require(managerDebitAllowance[depositor][token] >= quantity, "Insufficient direct debit allowance.");
            managerDebitAllowance[depositor][token] -= quantity;
        }
        require(token.allowance(depositor, this) >= quantity, "Insufficient depositor allowance.");
        uint result = token.transferFrom(depositor, this, quantity) ? 0 : 1;
        _addOwnedTokenIfBalance(token);
        managementLog.push(LogEntry(LogType.Deposit, now, token, quantity, depositor, result, annotation));
        return result;
    }
}
