var CosmoCoinIco = artifacts.require("./ico/CosmoCoinIco.sol");

module.exports = function(deployer, network, accounts) {
  var ethFundDeposit = accounts[0];
  var privateSaleWallet = accounts[1];
  var advisorWallet = accounts[2];
  var ecosystemWallet = accounts[3];
  var cosmochainTeamWallet = accounts[4];
  var reserveWallet = accounts[5];
  var scaleDownFactor = 1;
  deployer.deploy(
    CosmoCoinIco,
    ethFundDeposit,
    privateSaleWallet,
    advisorWallet,
    ecosystemWallet,    
    cosmochainTeamWallet,
    reserveWallet,
    scaleDownFactor
  );
};
