/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SafeDecimalMath.sol
version:    1.0
author:     Anton Jurisevic

date:       2018-2-5

auditors: Sigma Prime, https://github.com/sigp/havven-audit
          BlocTrax, https://havven.io/uploads/havven_bloctrax_security_audit_june-6th.pdf

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A fixed point decimal library that provides basic mathematical
operations, and checks for unsafe arguments, for example that
would lead to overflows.

Exceptions are thrown whenever those unsafe operations
occur.

-----------------------------------------------------------------
*/

pragma solidity 0.4.24;
pragma experimental "v0.5.0";


/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals (including fiat, ether, and nomin quantities).
 */
contract SafeDecimalMath {

    /* Number of decimal places in the representation. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /**
     * @return True iff adding x and y will not overflow.
     */
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

    /**
     * @return The result of adding x and y, throwing an exception in case of overflow.
     */
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y, "Safe add failed");
        return x + y;
    }

    /**
     * @return True iff subtracting y from x will not overflow in the negative direction.
     */
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

    /**
     * @return The result of subtracting y from x, throwing an exception in case of overflow.
     */
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x, "Safe sub failed");
        return x - y;
    }

    /**
     * @return True iff multiplying x and y would not overflow.
     */
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

    /**
     * @return The result of multiplying x and y, throwing an exception in case of overflow.
     */
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y, "Safe mul failed");
        return p;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals. Throws an exception in case of overflow.
     * 
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256.
     * Incidentally, the internal division always rounds down: one could have rounded to the nearest integer,
     * but then one would be spending a significant fraction of a cent (of order a microether
     * at present gas prices) in order to save less than one part in 0.5 * 10^18 per operation, if the operands
     * contain small enough fractional components. It would also marginally diminish the 
     * domain this function is defined upon. 
     */
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return safeMul(x, y) / UNIT;

    }

    /**
     * @return True iff the denominator of x/y is nonzero.
     */
    function divIsSafe(uint, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

    /**
     * @return The result of dividing x by y, throwing an exception if the divisor is zero.
     */
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Although a 0 denominator already throws an exception,
         * it is equivalent to a THROW operation, which consumes all gas.
         * A require statement emits REVERT instead, which remits remaining gas. */
        require(y != 0, "Denominator cannot be zero");
        return x / y;
    }

    /**
     * @return The result of dividing x by y, interpreting the operands as fixed point decimal numbers.
     * @dev Throws an exception in case of overflow or zero divisor; x must be less than 2^256 / UNIT.
     * Internal rounding is downward: a similar caveat holds as with safeMul_dec().
     */
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return safeDiv(safeMul(x, UNIT), y);
    }

    /**
     * @dev Convert an unsigned integer to a unsigned fixed-point decimal.
     * Throw an exception if the result would be out of range.
     */
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
    }
}

/*
-----------------------------------------------------------------------------
MIT License

Copyright (c) 2018 Havven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-----------------------------------------------------------------------------
*/