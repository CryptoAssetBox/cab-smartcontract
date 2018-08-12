pragma solidity ^0.4.18;

import './CABoxToken.sol';
import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title CABoxCrowdsale
 * @dev CABoxCrowdsale is a completed contract for managing a token crowdsale.
 * CABoxCrowdsale have a start and end timestamps, where investors can make
 * token purchases and the CABoxCrowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract CABoxCrowdsale is Ownable{
    using SafeMath for uint256;

    // The token being sold
    CABoxToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // address where development funds are collected
    address public devWallet;

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

    function CABoxCrowdsale() public {
        token = createTokenContract();
        startTime = 1535155200;
        endTime = 1540771200;
        wallet = 0x9BeAbD0aeB08d18612d41210aFEafD08fb84E9E8;
        devWallet = 0x13dF1d8F51324a237552E87cebC3f501baE2e972;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific token.
    function createTokenContract() internal returns (CABoxToken) {
        return new CABoxToken();
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
        uint256 bonusRate = getBonusRate();
        uint256 tokens = weiAmount.mul(bonusRate);

        token.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function getBonusRate() internal view returns (uint256) {
        uint64[5] memory tokenRates = [uint64(24000),uint64(20000),uint64(16000),uint64(12000),uint64(8000)];

        // apply bonus for time
        uint64[5] memory timeStartsBoundaries = [uint64(1535155200),uint64(1538352000),uint64(1538956800),uint64(1539561600),uint64(1540166400)];
        uint64[5] memory timeEndsBoundaries = [uint64(1538352000),uint64(1538956800),uint64(1539561600),uint64(1540166400),uint64(1540771200)];
        uint[5] memory timeRates = [uint(500),uint(250),uint(200),uint(150),uint(100)];

        uint256 bonusRate = tokenRates[0];

        for (uint i = 0; i < 5; i++) {
            bool timeInBound = (timeStartsBoundaries[i] <= now) && (now < timeEndsBoundaries[i]);
            if (timeInBound) {
                bonusRate = tokenRates[i] + tokenRates[i] * timeRates[i] / 1000;
            }
        }

        return bonusRate;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value * 750 / 1000);
        devWallet.transfer(msg.value * 250 / 1000);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        bool withinPeriod = now >= startTime && now <= endTime;

        return nonZeroPurchase && withinPeriod;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool timeEnded = now > endTime;

        return timeEnded;
    }

    // update token contract
    function updateCABoxToken(address _tokenAddress) onlyOwner{
        require(_tokenAddress != address(0));
        token.transferOwnership(_tokenAddress);

        TokenContractUpdated(true);
    }

    // transfer tokens
    function transferTokens(address _to, uint256 _amount) onlyOwner {
        require(_to != address(0));

        token.transfer(_to, _amount);
    }
}