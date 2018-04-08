pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/token/CosmoCoin.sol";

contract TestCosmoCoinUnit {
    CosmoCoin cosmoCoin;

    uint256 constant DEFAULT_GAS = 200000;
    uint256 constant DEFAULT_TOKEN_QUANTITY = 500;
    address constant TEST_ADDRESS = 0x9E2A81947C635c16948a87a891f6041d016EDc65;

    function beforeEach() public {
        cosmoCoin = new CosmoCoin(this, TEST_ADDRESS);
    }

    function testIcoAddressEqualsInstantiator() public {
        address icoAddress = cosmoCoin.ico();
        address expected = this;
        
        Assert.equal(icoAddress, expected, "Ico address should be set to instance creator");
    }

    function testAdminAddressEqualsPassedIn() public {
        address admin = cosmoCoin.admin();
        address expected = TEST_ADDRESS;

        Assert.equal(admin, expected, "Admin address should be set to passed in arg");
    }

    function testFrozenStates() public {
        Assert.isTrue(cosmoCoin.tokensAreFrozen(), "Tokens should be frozen when initialized");
        cosmoCoin.defrostTokens();
        Assert.isTrue(!cosmoCoin.tokensAreFrozen(), "Tokens should NOT be frozen after defrost");
        cosmoCoin.frostTokens();
        Assert.isTrue(cosmoCoin.tokensAreFrozen(), "Tokens should be frozen after frost");
    }

    function testIcoAddressNotEqualsContractAddress() public {
        CosmoCoin cosmoCoinAlt = new CosmoCoin(TEST_ADDRESS, this);
        address icoAddress = cosmoCoinAlt.ico();
        address adminAddress = cosmoCoinAlt.admin();
        address icoNotExpected = this;
        address adminNotExpected = TEST_ADDRESS;
        
        Assert.notEqual(icoAddress, icoNotExpected, "Ico address should not equal deployed contract addresss");
        Assert.notEqual(adminAddress, adminNotExpected, "Admin address should not equal deployed contract addresss");
    }

    function testBalanceShouldStartWithZero() public {
        uint256 zeroBalance = cosmoCoin.balanceOf(this);

        Assert.isZero(zeroBalance, "Addresses should have default balance of 0");
    }

    function testBalanceIncreasedAfterMinting() public {
        cosmoCoin.defrostTokens();
        cosmoCoin.mintTokens(this, DEFAULT_TOKEN_QUANTITY);
        uint256 balanceAfterMint = cosmoCoin.balanceOf(this);
        uint256 expected = DEFAULT_TOKEN_QUANTITY;

        Assert.equal(balanceAfterMint, expected, "Balance increased by amount specified after minting");
    }

    function testAdminCanMintWhenFrozen() public {
        cosmoCoin.frostTokens();
        cosmoCoin.mintTokens(this, DEFAULT_TOKEN_QUANTITY);
        uint256 balanceAfterMint = cosmoCoin.balanceOf(this);
        uint256 expected = DEFAULT_TOKEN_QUANTITY;

        Assert.equal(balanceAfterMint, expected, "Admin should be able to mint tokens even when frozen");
    }
    
    function testAdminCanTransferWhenFrozen() public {
        address icoAddress = cosmoCoin.ico();
        cosmoCoin.frostTokens();
        cosmoCoin.mintTokens(icoAddress, DEFAULT_TOKEN_QUANTITY);
        cosmoCoin.approve(icoAddress, DEFAULT_TOKEN_QUANTITY);
        cosmoCoin.transferFrom(icoAddress, TEST_ADDRESS, DEFAULT_TOKEN_QUANTITY);
        uint256 expected = DEFAULT_TOKEN_QUANTITY;
        uint256 balanceAfterTransfer = cosmoCoin.balanceOf(TEST_ADDRESS);
        uint256 emptyBalance = cosmoCoin.balanceOf(this);

        Assert.equal(balanceAfterTransfer, expected, "Admin should be able to transfer even when frozen");
        Assert.equal(emptyBalance, 0, "Sender balance should be 0 after transfer");
    }
}
