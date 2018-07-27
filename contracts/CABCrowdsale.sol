pragma solidity ^0.4.18;

import './CABoxToken.sol';
import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title CABCrowdsale
 * @dev CABCrowdsale is a completed contract for managing a token crowdsale.
 * CABCrowdsale have a start and end timestamps, where investors can make
 * token purchases and the CABCrowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract CABCrowdsale is Ownable{
    using SafeMath for uint256;

    // The token being sold
    CABoxToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of hard cap
    uint256 public cap;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event TokenContractUpdated(bool state);

    event WalletAddressUpdated(bool state);

    function CABCrowdsale() public {
        token = CABoxToken(0xc363c1ebc630eb578d5e756373a108559808d1b1);
        startTime = 1533859200;
        endTime = 1544572800;
        rate = 10000;
        wallet = 0x21dbE958B2a7BeB4c8193d0B2EDec4c013D5Dfc7;
        cap = 74000000000000000000000;
    }


    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinCap = weiRaised.add(msg.value) <= cap;

        return withinPeriod && nonZeroPurchase && withinCap;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        bool timeEnded = now > endTime;

        return timeEnded || capReached;
    }

    // update token contract
    function updateCABoxToken(address _tokenAddress) onlyOwner{
        require(_tokenAddress != address(0));
        token = CABoxToken(_tokenAddress);

        TokenContractUpdated(true);
    }

    // update wallet address
    function updateWalletAddress(address _newWallet) onlyOwner {
        require(_newWallet != address(0));
        wallet = _newWallet;

        WalletAddressUpdated(true);
    }

}
