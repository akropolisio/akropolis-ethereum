pragma solidity ^0.4.24;

import "./interfaces/ERC20Token.sol";
import "./utils/SafeMultiprecisionDecimalMath.sol";
import "./utils/IterableSet.sol";
import "./utils/Owned.sol";

contract Ticker is Owned, SafeMultiprecisionDecimalMath {
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
        IterableSet.Set whitelist;
        IterableSet.Set blacklist;
    }

    constructor() 
        Owned(msg.sender)
        public
    {}

    modifier onlyOracle(address oracle) {
        OraclePermissions storage permissions = oracles[oracle];
        require(permissions.isOracle, "Sender is not oracle.");
        _;
    }

    function isOracle(address oracle) 
        external
        view
        returns (bool)
    {
        return oracles[oracle].isOracle;
    }

    function isUniversalOracle(address oracle)
        external
        view
        returns (bool)
    {
        return oracles[oracle].isUniversal;
    }

    function isOracleFor(address oracle, ERC20Token token)
        public
        view
        returns (bool)
    {
        OraclePermissions storage permissions = oracles[oracle];
        return (
            permissions.isOracle && // Implies sets are initialised.
            !permissions.blacklist.contains(token) &&
            (permissions.isUniversal || permissions.whitelist.contains(token))
        );
    }

    function addOracle(address oracle)
        external
        onlyOwner
    {
        OraclePermissions storage permissions = oracles[oracle];
        require(!permissions.isOracle, "Sender is already an oracle.");
        permissions.isOracle = true;
        permissions.whitelist.initialise();
        permissions.blacklist.initialise();
    }

    function makeUniversalOracle(address oracle)
        external
        onlyOwner
        onlyOracle(oracle)
    {
        OraclePermissions storage permissions = oracles[oracle];
        permissions.isUniversal = true;
    }

    function unmakeUniversalOracle(address oracle)
        external
        onlyOwner
        onlyOracle(oracle)
    {
        OraclePermissions storage permissions = oracles[oracle];
        permissions.isUniversal = false;
    }

    function addToWhitelist(address oracle, ERC20Token token) 
        external
        onlyOwner
        onlyOracle(oracle)
    {
        oracles[oracle].whitelist.add(token);
    }

    function removeFromWhitelist(address oracle, ERC20Token token) 
        external
        onlyOwner
        onlyOracle(oracle)
    {
        oracles[oracle].whitelist.remove(token);
    }

    function addToBlacklist(address oracle, ERC20Token token) 
        external
        onlyOwner
        onlyOracle(oracle)
    {
        oracles[oracle].blacklist.add(token);
    }

    function removeFromBlacklist(address oracle, ERC20Token token) 
        external
        onlyOwner
        onlyOracle(oracle)
    {
        oracles[oracle].blacklist.remove(token);
    }

    function removeOracle(address oracle)
        external
        onlyOwner
    {
        OraclePermissions storage permissions = oracles[oracle];
        delete permissions.isOracle;
        delete permissions.isUniversal;
        permissions.whitelist.destroy();
        permissions.blacklist.destroy();
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

            // Sender must be approved for each token they wish to update.
            require(isOracleFor(msg.sender, token), "Sender is not oracle.");
            history[token].push(PriceData(prices[i], now, msg.sender));
        }
    }
    
    function historyLength(ERC20Token token)
        public
        view
        returns (uint)
    {
        return history[token].length;
    }

    function hasFreshPrice(ERC20Token token, uint requiredFreshness)
        public
        view
        returns (bool)
    {
        PriceData[] storage tokenHistory = history[token];
        uint length = tokenHistory.length;
        return length > 0 &&
               now - requiredFreshness < tokenHistory[length-1].timestamp;
    }

    function latestPriceData(ERC20Token token)
        public
        view
        returns (uint price, uint timestamp, address oracle)
    {
        PriceData[] storage tokenHistory = history[token];
        uint length = tokenHistory.length;
        if (length == 0) {
            return (0, 0, address(0));
        }
        PriceData storage latest = tokenHistory[length-1];
        return (latest.price, latest.timestamp, latest.oracle);
    }

    function price(ERC20Token token)
        public
        view
        returns (uint)
    {
        (uint tokenPrice, , ) = latestPriceData(token);
        return tokenPrice;
    }

    function value(ERC20Token token, uint quantity) 
        public
        view
        returns (uint)
    {
        return safeMul_mpdec(quantity, token.decimals(),
                             price(token), denominationDecimals,
                             denominationDecimals);
    }

    function prices(ERC20Token[] tokens)
        public
        view
        returns (uint[])
    {
        uint numTokens = tokens.length;
        uint[] memory tokenPrices = new uint[](numTokens);
        for (uint i; i < numTokens; i++) {
            tokenPrices[i] = price(tokens[i]);
        }
        return tokenPrices;
    }

    function values(ERC20Token[] tokens, uint[] quantities) 
        public
        view
        returns (uint[])
    {
        uint numTokens = tokens.length;
        uint[] memory vals = new uint[](numTokens);
        for (uint i; i < numTokens; i++) {
            vals[i] = value(tokens[i], quantities[i]);
        }
        return vals;
    }

    function rate(ERC20Token base, ERC20Token quote)
        public
        view
        returns (uint)
    {
        uint quoteDecimals = quote.decimals();
        return safeDiv_mpdec(price(base), base.decimals(),
                             price(quote), quoteDecimals,
                             quoteDecimals);
    }
}
