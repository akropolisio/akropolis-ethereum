pragma solidity 0.4.24;
pragma experimental "v0.5.0";

import "../interfaces/ERC20Token.sol";
import "./Owned.sol";

contract ERC20Faucet is Owned {

    uint public numTokens = 2000;
    mapping(address => uint) public timeLastWithdrawn;
    uint public withdrawCooldown = 10 minutes;

    constructor(address _owner)
        Owned(_owner)
        public
    {}

    function setNumTokens(uint newNumber)
        external
        onlyOwner
    {
        numTokens = newNumber;
    }

    function setCooldown(uint newCooldown)
        external
        onlyOwner
    {
        withdrawCooldown = newCooldown;
    }

    function adminWithdraw(ERC20Token tokenToWithdraw, uint quantity)
        external
        onlyOwner
    {
        tokenToWithdraw.transfer(msg.sender, quantity);
    }

    function vendTokens(ERC20Token token)
        external
    {
        require(timeLastWithdrawn[msg.sender] + withdrawCooldown < now, "TOO SOON.");
        uint quantity = numTokens * 10 ** uint(token.decimals());
        require(token.transfer(msg.sender, quantity), "Transfer failed");
        timeLastWithdrawn[msg.sender] = now;
    }
}
