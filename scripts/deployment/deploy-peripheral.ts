import { ethers } from "hardhat";

async function deployPeripheral() {
  console.log("deploying access-control");
  const AccessControl = await ethers.getContractFactory("AccessControl");
  const accessControl = await AccessControl.deploy();

  console.log("deploying atm");
  const ATM = await ethers.getContractFactory("ATM");
  const atm = await ATM.deploy();

  console.log("deploying oracle");
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.deploy();

  console.log("deploying referral");
  const Referral = await ethers.getContractFactory("Referral");
  const referral = await Referral.deploy();

  console.log("deploying token libs");
  const TokenLibs = await ethers.getContractFactory("TokenLibs");
  const tokenLibs = await TokenLibs.deploy();

  console.log(`accessControl: "${accessControl.address}",`);
  console.log(`atm: "${atm.address}",`);
  console.log(`simplePriceFeed: "${simplePriceFeed.address}",`);
  console.log(`referral: "${referral.address}",`);
  console.log(`tokenLibs: "${tokenLibs.address}",`);

  console.log(`
  accessControl=${accessControl.address}
  atm=${atm.address}
  simplePriceFeed=${simplePriceFeed.address}
  referral=${referral.address}
  tokenLibs=${tokenLibs.address}
  `);

  return {
    accessControlAddress: accessControl.address,
    atmAddress: atm.address,
    simplePriceFeedAddress: simplePriceFeed.address,
    referralAddress: referral.address,
    tokenLibsAddress: tokenLibs.address,
  };
}

export default deployPeripheral;
