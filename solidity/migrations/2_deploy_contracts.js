const TokenERC20 = artifacts.require("TokenERC20");
const Fields = artifacts.require("Fields");
const User = artifacts.require("User");
const Winner = artifacts.require("Winner");
const PlayGame = artifacts.require("playGame");

module.exports = function (deployer) {
  deployer.deploy(TokenERC20,1000000,"HSLUToken","HSLU").then(function() {
    deployer.deploy(Fields)
    deployer.deploy(User)
    deployer.deploy(Winner)
    return deployer.deploy(PlayGame,TokenERC20.address)
  });
}
