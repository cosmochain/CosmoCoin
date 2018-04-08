pragma solidity ^0.4.18;

import "../token/CosmoCoin.sol";
import "../util/SafeMath.sol";

contract CosmoCoinIco {
    using SafeMath for uint256;

    // Pass own contract address when creating token
    CosmoCoin public cosmoCoin;

    mapping(address => string) public registeredAddresses;

    uint256 public scaleDownFactor;

    // ICO parameters
    Stages public currentStage;
    uint256 public conversionRatio = 10000; // 1 ETH = 10000 Token
    uint256 public reservePoolUsed = 0;
    uint256 public ceiling = 0;

    // Bonus Eligibility Criteria
    uint256 public preEth100 = 100 ether;
    uint256 public preEth500 = 500 ether;
    uint256 public preEth2000 = 2000 ether;

    uint256 public earlyBirdEth100 = 100 ether;
    uint256 public earlyBirdEth500 = 500 ether;
    uint256 public earlyBirdEth2000 = 2000 ether;

    // Bonus Multipliers
    uint256 public preBonusTier1 = 1050;
    uint256 public preBonusTier2 = 1100;
    uint256 public preBonusTier3 = 1150;
    uint256 public preBonusTier4 = 1200;


    uint256 public earlyBirdBonusTier1 = 1025;
    uint256 public earlyBirdBonusTier2 = 1050;
    uint256 public earlyBirdBonusTier3 = 1100;
    uint256 public earlyBirdBonusTier4 = 1150;

    uint256 public bonusDenominator = 1000;

    // Eth Wallets
    address public ethFundDeposit;

    // Token Wallets
    address public privateSaleWallet;
    address public advisorWallet;
    address public ecosystemWallet;
    address public cosmochainTeamWallet;

    address public reserveWallet;

    // Addresses
    address admin;

    // Running total of tokens purchased during crowdsale
    uint256 public totalEthereumReceivedInWei = 0;
    uint256 public totalTokensGrantedInWei = 0;

    // Distribution
    uint256 privateSalePortion = 30 * (10 ** 7) * 1 ether;
    uint256 advisorPortion = 10 * (10 ** 7) * 1 ether;
    uint256 ecosystemPortion = 20 * (10 ** 7) * 1 ether;
    uint256 cosmochainTeamPortion = 10 * (10 ** 7) * 1 ether;

    uint256 reservePoolSupply = 10 * (10 ** 7) * 1 ether;
    uint256 totalPublicIcoSupply = 20 * (10 ** 7) * 1 ether;
    uint256 totalTokenSupply = (10 ** 9) * 1 ether;

    // Cumulative caps for each round (unit: Ethereum)
    uint256 public preSaleCapInWei = 5000 ether;
    uint256 public mainRoundCapInWei = 15000 ether;
    uint256 public reservePoolCapInWei = 10000 ether;
    
    // Minimum Investments for each round
    uint256 public preMinInvestment = 5 ether;
    uint256 public earlyBirdMinInvestment = 1 ether;
    uint256 public mainMinInvestment = 1 ether;

    // Stages enum
    enum Stages {
        Deployed,
        PreSaleStarted,
        PreSalePaused,
        PreSaleEnded,
        EarlyBirdRoundStarted,
        EarlyBirdRoundPaused,
        EarlyBirdRoundEnded,
        MainRoundStarted,
        MainRoundPaused,
        MainRoundEnded,
        Finished
    }

    // Events
    event TokenPurchase(address indexed investor, uint256 value, uint256 amount);
    event AddressRegistered(address indexed investor);

    /** Modifiers **/
    // Only executable by manager.
    modifier adminOnly {
        require(msg.sender == admin);
        _;
    }

    modifier atStage(Stages _stage) {
        require(currentStage == _stage);
        _;
    }

    modifier saleOpen() {
        require(
            (currentStage == Stages.PreSaleStarted) || (currentStage == Stages.MainRoundStarted) || (currentStage == Stages.EarlyBirdRoundStarted)
        );
        _;
    }

    // Constructor
    function CosmoCoinIco(
        address _ethFundDeposit, 
        address _privateSaleWallet,
        address _advisorWallet,
        address _ecosystemWallet,
        address _cosmochainTeamWallet,
        address _reserveWallet,
        uint256 _scaleDownFactor
        ) public
    {
        require(_ethFundDeposit != address(0));
        admin = msg.sender;
        cosmoCoin = new CosmoCoin(this, admin);
        ethFundDeposit = _ethFundDeposit;
        privateSaleWallet = _privateSaleWallet;
        advisorWallet = _advisorWallet;
        ecosystemWallet = _ecosystemWallet;
        cosmochainTeamWallet = _cosmochainTeamWallet;
        reserveWallet = _reserveWallet;
        scaleDownFactor = _scaleDownFactor;
        currentStage = Stages.Deployed;
        cosmoCoin.frostTokens();

        preEth100 = preEth100.div(scaleDownFactor);
        preEth500 = preEth500.div(scaleDownFactor);
        preEth2000 = preEth2000.div(scaleDownFactor);

        earlyBirdEth100 = earlyBirdEth100.div(scaleDownFactor);
        earlyBirdEth500 = earlyBirdEth500.div(scaleDownFactor);
        earlyBirdEth2000 = earlyBirdEth2000.div(scaleDownFactor);

        privateSalePortion = privateSalePortion.div(scaleDownFactor);
        advisorPortion = advisorPortion.div(scaleDownFactor);
        ecosystemPortion = ecosystemPortion.div(scaleDownFactor);
        cosmochainTeamPortion = cosmochainTeamPortion.div(scaleDownFactor);

        reservePoolSupply = reservePoolSupply.div(scaleDownFactor);
        totalPublicIcoSupply = totalPublicIcoSupply.div(scaleDownFactor);
        totalTokenSupply = totalTokenSupply.div(scaleDownFactor);

        preSaleCapInWei = preSaleCapInWei.div(scaleDownFactor);
        mainRoundCapInWei = mainRoundCapInWei.div(scaleDownFactor);
        reservePoolCapInWei = reservePoolCapInWei.div(scaleDownFactor);

        preMinInvestment = preMinInvestment.div(scaleDownFactor);
        earlyBirdMinInvestment = earlyBirdMinInvestment.div(scaleDownFactor);
        mainMinInvestment = mainMinInvestment.div(scaleDownFactor);

        _distributeNonCrowdsaleFunds();
    }

    // Stage Controls
    function startPreSale() public adminOnly atStage(Stages.Deployed) {
        currentStage = Stages.PreSaleStarted;
        ceiling = ceiling.add(preSaleCapInWei);
    }

    function endPreSale() public adminOnly atStage(Stages.PreSaleStarted) {
        currentStage = Stages.PreSaleEnded;
        depositFunds();
    }

    function startEarlyBirdRound() public adminOnly atStage(Stages.PreSaleEnded) {
        currentStage = Stages.EarlyBirdRoundStarted;
        ceiling = ceiling.add(mainRoundCapInWei);
    }

    function endEarlyBirdRound() public adminOnly atStage(Stages.EarlyBirdRoundStarted) {
        currentStage = Stages.EarlyBirdRoundEnded;
        depositFunds();
    }

    function startMainRound() public adminOnly atStage(Stages.EarlyBirdRoundEnded) {
        currentStage = Stages.MainRoundStarted;
        // leaving ceiling as is
    }

    function endMainRound() public adminOnly atStage(Stages.MainRoundStarted) {
        currentStage = Stages.MainRoundEnded;
        depositFunds();
        cosmoCoin.defrostTokens();
    }

    function pausePreSale() public adminOnly atStage(Stages.PreSaleStarted) {
        currentStage = Stages.PreSalePaused;
    }

    function pauseEarlyBirdRound() public adminOnly atStage(Stages.EarlyBirdRoundStarted) {
        currentStage = Stages.EarlyBirdRoundPaused;
    }

    function pauseMainRound() public adminOnly atStage(Stages.MainRoundStarted) {
        currentStage = Stages.MainRoundPaused;
    }

    function restartPreSale() public adminOnly atStage(Stages.PreSalePaused) {
        currentStage = Stages.PreSaleStarted;
    }

    function restartEarlyBirdRound() public adminOnly atStage(Stages.EarlyBirdRoundPaused) {
        currentStage = Stages.EarlyBirdRoundStarted;
    }

    function restartMainRound() public adminOnly atStage(Stages.MainRoundPaused) {
        currentStage = Stages.MainRoundStarted;
    }

    // fallback for adhoc cases
    function freezeTokens() public adminOnly {
        cosmoCoin.frostTokens();
    }

    function unfreezeTokens() public adminOnly {
        cosmoCoin.defrostTokens();
    }

    // Transfer Fund
    function depositFunds() public adminOnly {
        ethFundDeposit.transfer(address(this).balance);
    }

    function _distributeNonCrowdsaleFunds() internal {
        cosmoCoin.mintTokens(privateSaleWallet, privateSalePortion);
        cosmoCoin.mintTokens(advisorWallet, advisorPortion);
        cosmoCoin.mintTokens(ecosystemWallet, ecosystemPortion);
        cosmoCoin.mintTokens(cosmochainTeamWallet, cosmochainTeamPortion);
        TokenPurchase(privateSaleWallet, 0x0, privateSalePortion);
        TokenPurchase(advisorWallet, 0x0, advisorPortion);
        TokenPurchase(ecosystemWallet, 0x0, ecosystemPortion);
        TokenPurchase(cosmochainTeamWallet, 0x0, cosmochainTeamPortion);
    }

    // Check State
    function totalEthRaised() public view adminOnly returns (uint256) {
        return address(this).balance;
    }

    function totalTokensGrantedInWei() public view returns (uint256) {
        return totalTokensGrantedInWei;
    }

    // Investment Processing
    function () public saleOpen payable {
        _validateMinInvestment();
        _validateCapAvailable();
        _grantTokens();
    }

    function finishInvestment() public adminOnly atStage(Stages.MainRoundEnded) {
        if (totalTokensGrantedInWei > totalPublicIcoSupply) {
            uint256 weiExceeded = totalTokensGrantedInWei.sub(totalPublicIcoSupply);
            uint256 reservePortion = reservePoolSupply.sub(weiExceeded);
            cosmoCoin.mintTokens(reserveWallet, reservePortion);
            TokenPurchase(reserveWallet, 0x0, reservePortion);
        } else {
            cosmoCoin.mintTokens(reserveWallet, reservePoolSupply);
            TokenPurchase(reserveWallet, 0x0, reservePoolSupply);
        }
        currentStage = Stages.Finished;
    }

    function register(string _addr) public {
        AddressRegistered(msg.sender);
        registeredAddresses[msg.sender] = _addr;
    }

    function registeredAddress(address _who) public view returns (string) {
        return registeredAddresses[_who];
    }

    function _validateMinInvestment() internal view {
        uint256 weiAmount = msg.value;
        if (currentStage == Stages.PreSaleStarted) {
            require(weiAmount >= preMinInvestment);
        } else if (currentStage == Stages.EarlyBirdRoundStarted) {
            require(weiAmount >= earlyBirdMinInvestment);
        } else if (currentStage == Stages.MainRoundStarted) {
            require(weiAmount >= mainMinInvestment);
        } else {
            revert(); // should never happen. Emit event
        }
    }

    function _calculateMultiplier() internal view returns (uint256) {
        uint256 weiAmount = msg.value;
        uint256 multiplier = 0;
        if (currentStage == Stages.PreSaleStarted) {
            if (weiAmount < preEth100) {
                multiplier = preBonusTier1;
            } else if (weiAmount < preEth500) {
                multiplier = preBonusTier2;
            } else if (weiAmount < preEth2000) {
                multiplier = preBonusTier3;
            } else { // more than 2000 eth
                multiplier = preBonusTier4;
            }
        } else if (currentStage == Stages.EarlyBirdRoundStarted) {
            if (weiAmount < earlyBirdEth100) {
                multiplier = earlyBirdBonusTier1;
            } else if (weiAmount < earlyBirdEth500) {
                multiplier = earlyBirdBonusTier2;
            } else if (weiAmount < earlyBirdEth2000) {
                multiplier = earlyBirdBonusTier3;
            } else { // more than 2000 eth
                multiplier = earlyBirdBonusTier4;
            }
        } else if (currentStage == Stages.MainRoundStarted) {
            multiplier = bonusDenominator;
        } else {
            revert(); // should never happen. Emit event
        }
        require(multiplier > 0);
        return multiplier;
    }

    function _validateCapAvailable() internal view {
        require(totalEthereumReceivedInWei.add(msg.value) <= ceiling);
    }

    function _grantTokens() internal {
        uint256 tokensInWei = msg.value.mul(conversionRatio).mul(_calculateMultiplier()).div(bonusDenominator);
        cosmoCoin.mintTokens(msg.sender, tokensInWei);
        totalEthereumReceivedInWei = totalEthereumReceivedInWei.add(msg.value);
        totalTokensGrantedInWei = totalTokensGrantedInWei.add(tokensInWei);
        TokenPurchase(msg.sender, msg.value, tokensInWei);
    }
}
