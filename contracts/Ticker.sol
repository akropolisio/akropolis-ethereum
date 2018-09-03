pragma solidity ^0.4.24;

import "./interfaces/ERC20Token.sol";
import "./utils/Unimplemented.sol";
import "./utils/SafeMultiprecisionDecimalMath.sol";
import "./utils/IterableSet.sol";
import "./utils/Owned.sol";

contract Ticker is Owned, SafeMultiprecisionDecimalMath, Unimplemented {
    using IterableSet for IterableSet.Set;
    
    ERC20Token public denomination;
    uint8 public denominationDecimals;

    mapping(address => PriceData[]) history;
    mapping(address => OraclePermissions) oracles;

    struct PriceData {
        uint price;
        uint timestamp;
        address oracle;
    }

    struct OraclePermissions {
        bool isOracle;
        bool isUniversal;
        IterableSet.Set allowed;
        IterableSet.Set disallowed;
    }

    constructor() 
        Owned(msg.sender)
    {}

    function isOracle(address oracle) 
        external
        returns (bool)
    {
        return oracles[oracle].isOracle;
    }

    function isUniversalOracle(address oracle)
        external
        returns (bool)
    {
        return oracles[oracle].isUniversal;
    }

    function isOracleFor(address oracle, ERC20Token token)
        public
        returns (bool)
    {
        OraclePermissions storage permissions = oracles[oracle];
        return (
            permissions.isOracle && // Implies sets are initialised.
            !permissions.disallowed.contains(token) &&
            ( permissions.isUniversal || permissions.allowed.contains(token) )
        );
    }

    function addOracle(address oracle)
        external
        onlyOwner
    {
        require(!oracles[oracle].isOracle, "Is already an oracle.");

        OraclePermissions storage permissions = oracles[oracle];
        permissions.isOracle = true;
        permissions.allowed.initialise();
        permissions.disallowed.initialise();
    }

    function removeOracle(address oracle)
        external
        onlyOwner
    {
        OraclePermissions storage permissions = oracles[oracle];
        delete permissions.isOracle;
        delete permissions.isUniversal;
        permissions.allowed.destroy();
        permissions.disallowed.destroy();
    }

    function setDenomination(ERC20Token token)
        external
        onlyOwner
    {
        denomination = token;
        denominationDecimals = token.decimals();
    }

    function updatePrices(ERC20Token[] tokens, uint[] prices)
        external
    {
        require(tokens.length == prices.length, "Token and price array lengths differ.");

        for (uint i; i < tokens.length; i++) {
            ERC20Token token = tokens[i];
            PriceData[] storage tokenHistory = history[token];

            // Sender must be approved, and disallow multiple updates per block.
            if (isOracleFor(msg.sender, token) && tokenHistory[tokenHistory.length - 1].timestamp < now) {
                tokenHistory.push(PriceData(prices[i], now, msg.sender));
            }
        }
    }
    
    function historyLength(ERC20Token token)
        public
        returns (uint)
    {
        return history[token].length;
    }

    function latestPriceData(ERC20Token token)
        public
        returns (uint price, uint timestamp, address oracle)
    {
        PriceData[] storage tokenHistory = history[token];
        PriceData storage latest = tokenHistory[tokenHistory.length - 1];
        return (latest.price, latest.timestamp, latest.oracle);
    }

    function price(ERC20Token token)
        public
        returns (uint)
    {
        PriceData[] storage tokenHistory = history[token];
        return tokenHistory[tokenHistory.length - 1].price;
    }

    function value(ERC20Token token, uint quantity) 
        public
        returns (uint)
    {
        return safeMul_mpdec(quantity, token.decimals(),
                             price(token), denominationDecimals,
                             denominationDecimals);
    }

    function rate(ERC20Token base, ERC20Token quote)
        public
        returns (uint)
    {
        unimplemented();
    }
}
