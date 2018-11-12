var core = artifacts.require("./DFcore.sol");

module.exports = function(deployer) {
  deployer.deploy(core);
}
