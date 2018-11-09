/*
* The MIT License
*
* Copyright (c) 2017-2018 , Akropolis Decentralised Ltd (Gibraltar), http://akropolis.io
*
*/

pragma solidity ^0.4.24;

import "./interfaces/ERC20Token.sol";
import "./utils/SafeMultiprecisionDecimalMath.sol";
import "./utils/Set.sol";
import "./utils/Owned.sol";

contract Ticker is Owned, SafeMultiprecisionDecimalMath {
    using AddressSet for AddressSet.Set;
    
    ERC20Token public denomination;
    uint8 public denominationDecimals;

    mapping(address => TokenDetails) details;
    mapping(address => OraclePermissions) oracles;

    struct TokenDetails {
        bool isInitialised;
        uint8 decimals;
        PriceData[] history;
    }

    struct PriceData {
        uint price;
        uint timestamp;
        address oracle;
    }

    struct OraclePermissions {
        bool isOracle;
        bool isUniversal;
        AddressSet.Set whitelist;
        AddressSet.Set blacklist;
    }

    constructor(ERC20Token _denomination) 
        Owned(msg.sender)
        public
    {
        setDenomination(_denomination);
    }

    modifier onlyOracle(address oracle) {
        OraclePermissions storage permissions = oracles[oracle];
        require(permissions.isOracle, "Not oracle.");
        _;
    }

    function initialiseToken(ERC20Token token)
        public
    {
        details[token].isInitialised = true;
        details[token].decimals = token.decimals();
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
        require(!permissions.isOracle, "Already oracle.");
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
        public
        onlyOwner
    {
        denomination = token;
        denominationDecimals = token.decimals();
    }

    function updatePrices(ERC20Token[] tokens, uint[] prices)
        external
    {
        require(tokens.length == prices.length, "Array lengths differ.");

        for (uint i; i < tokens.length; i++) {
            ERC20Token token = tokens[i];

            // Sender must be approved for each token they wish to update.
            require(isOracleFor(msg.sender, token), "Not oracle for token.");
            TokenDetails storage tokenDetails = details[token];
            if (!tokenDetails.isInitialised) {
                initialiseToken(token);
            }
            details[token].history.push(PriceData(prices[i], now, msg.sender));
        }
    }
    
    function historyLength(ERC20Token token)
        public
        view
        returns (uint)
    {
        return details[token].history.length;
    }

    function isInitialised(ERC20Token token)
        public
        view
        returns (bool)
    {
        return details[token].isInitialised;
    }

    function hasFreshPrice(ERC20Token token, uint requiredFreshness)
        public
        view
        returns (bool)
    {
        TokenDetails storage tokenDetails = details[token];
        PriceData[] storage tokenHistory = details[token].history;
        return tokenDetails.isInitialised &&
               now - requiredFreshness < tokenHistory[tokenHistory.length-1].timestamp;
    }

    function latestPriceData(ERC20Token token)
        public
        view
        returns (uint price, uint timestamp, address oracle)
    {
        if (token == denomination) {
            return (unit(denominationDecimals), now, this);
        }

        TokenDetails storage tokenDetails = details[token];
        if (!tokenDetails.isInitialised) {
            return (0, 0, address(0));
        }
        PriceData[] storage tokenHistory = details[token].history;
        PriceData storage latest = tokenHistory[tokenHistory.length-1];
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

    function _value(uint tokenPrice, uint tokenDecimals, uint quantity)
        internal
        view
        returns (uint)
    {
        return safeMul_mpdec(quantity, tokenDecimals,
                             tokenPrice, denominationDecimals,
                             denominationDecimals);
    }

    function value(ERC20Token token, uint quantity) 
        public
        view
        returns (uint)
    {
        if (token == denomination) {
            return quantity;
        }
        return _value(price(token), details[token].decimals, quantity);
    }


    // Requires quotePrice is non-zero.
    function _rate(uint basePrice, uint baseDecimals, uint quotePrice, uint quoteDecimals)
        internal
        pure
        returns (uint)
    {
        return safeDiv_mpdec(basePrice, baseDecimals,
                             quotePrice, quoteDecimals,
                             quoteDecimals);
    }

    function rate(ERC20Token base, ERC20Token quote)
        public
        view
        returns (uint)
    {
        if (quote == denomination) {
            return price(base);
        }

        uint quotePrice = price(quote);
        if (quotePrice == 0) {
            return 0;
        }

        uint basePrice = price(base);
        if (basePrice == 0) {
            return 0;
        }

        return _rate(price(base), details[base].decimals, quotePrice, details[quote].decimals);
    }

    // Assumes quotePrice is non-zero.
    function _valueAtRate(uint basePrice, uint baseQuantity, uint baseDecimals,
                          uint quotePrice, uint quoteDecimals)
        internal
        pure
        returns (uint)
    {
        uint r = _rate(basePrice, baseDecimals, quotePrice, quoteDecimals);
        return safeMul_mpdec(baseQuantity, baseDecimals,
                             r, quoteDecimals,
                             quoteDecimals);
    }

    function valueAtRate(ERC20Token base, uint baseQuantity, ERC20Token quote)
        public
        view
        returns (uint)
    {
        if (quote == denomination) {
            return value(base, baseQuantity);
        }

        if (baseQuantity == 0) {
            return 0;
        }

        uint quotePrice = price(quote);
        if (quotePrice == 0) {
            return 0;
        }

        uint basePrice = price(base);
        if (basePrice == 0) {
            return 0;
        }

        return _valueAtRate(basePrice, baseQuantity, details[base].decimals,
                            quotePrice, details[quote].decimals);
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

    function valuesAtRate(ERC20Token[] tokens, uint[] quantities, ERC20Token quote)
        public
        view
        returns (uint[])
    {
        if (quote == denomination) {
            return values(tokens, quantities);
        }

        uint numTokens = tokens.length;
        uint[] memory vals = new uint[](numTokens);

        uint quotePrice = price(quote);
        if (quotePrice == 0) {
            return vals;
        }
        uint quoteDecimals = details[quote].decimals;

        for (uint i; i < numTokens; i++) {
            ERC20Token base = tokens[i];
            uint baseQuantity = quantities[i];
            uint basePrice = price(base);

            if (baseQuantity == 0 || basePrice == 0) {
                vals[i] = 0;
            } else {
                vals[i] = _valueAtRate(basePrice, baseQuantity, details[base].decimals,
                                       quotePrice, quoteDecimals);
            }
        }
        return vals;
    }
}
