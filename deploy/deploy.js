const { OwnerAddress } = require("../helper");

const { network } = require("hardhat");
module.exports = async ({ deployments, getNamedAccounts }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const args = [OwnerAddress];
  log("Deploying..................");

  const transport = await deploy("Transport", {
    from: deployer,
    log: true,
    args: args,
    waitConfirmation: network.config.blockConfirmations || 1,
  });
  console.log(`Transpont Deployed at ${transport.address}`);
};

module.exports.tags = ["all", "Transport"];
