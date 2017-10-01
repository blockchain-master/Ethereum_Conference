var MetaCoin = artifacts.require("./MetaCoin.sol");
var ConvertLib = artifacts.require("./ConvertLib.sol");
var Conference = artifacts.require("./Conference.sol");

module.exports = function(deployer) {
	deployer.deploy(Conference);
	deployer.deploy(ConvertLib);
	deployer.link(ConvertLib, MetaCoin);
	deployer.deploy(MetaCoin);
};
