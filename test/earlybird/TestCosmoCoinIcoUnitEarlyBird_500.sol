pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ico/CosmoCoinIco.sol";

contract TestCosmoCoinIcoUnitEarlyBird_500 {
    uint public initialBalance = 20000 finney;

    CosmoCoinIco cosmoCoinIco;

    uint256 constant DEFAULT_GAS = 200000;
    uint256 constant DEFAULT_TOKEN_QUANTITY = 500;

    address constant ETH_FUND_WALLET = 0x0219A893945F8E8c9Fd8c1a9B2ddD940F821af4a;
    address constant PRIVATE_SALE_WALLET = 0x9E2A81947C635c16948a87a891f6041d016EDc65;
    address constant ADVISOR_WALLET = 0x5D17d82345d13dc54dF7C5B6D2fd145f0B943c26;
    address constant ECOSYSTEM_WALLET = 0x0c68a991549c492eE659122C46798CE69Aee7934;
    address constant COSMOCHAIN_TEAM_WALLET = 0x96B740e6c86C7aaF40e4fD901Bdd32d5a0074aE3;
    address constant RESERVE_WALLET = 0x14E3909Afee20a8b840A0396c0eaF6E95D0AA843;
    address constant PARTICIPANT_WALLET = 0x433C9aCC4f8452c756dC22F3B0897C76dfCd7a5d;

    function beforeEach() public {
        cosmoCoinIco = new CosmoCoinIco(ETH_FUND_WALLET, PRIVATE_SALE_WALLET,
            ADVISOR_WALLET, ECOSYSTEM_WALLET, COSMOCHAIN_TEAM_WALLET, RESERVE_WALLET, 1000);
    }

    function testEarlyBirdBonus500() public {
        uint256 expectedBalance = 0;
        uint256 balance = 0;

        cosmoCoinIco.startPreSale();
        cosmoCoinIco.endPreSale();

        // Earlybird
        cosmoCoinIco.startEarlyBirdRound();

        cosmoCoinIco.pauseEarlyBirdRound();
        cosmoCoinIco.restartEarlyBirdRound();

        // 500 finney
        cosmoCoinIco.call.value(500 finney)();
        expectedBalance += 5500000 finney;
        balance = cosmoCoinIco.cosmoCoin().balanceOf(this);

        cosmoCoinIco.endEarlyBirdRound();
        Assert.equal(balance, expectedBalance, "");
        Assert.equal(ETH_FUND_WALLET.balance, 500 finney, "final balance");
        
    }
}
