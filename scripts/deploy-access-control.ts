import { ethers } from "hardhat";

async function deployAccessControl() {
  const AccessControl = await ethers.getContractFactory("AccessControl");
  const accessControl = await AccessControl.deploy();

  await accessControl.deployed();

  console.log("AccessControl deployed to:", accessControl.address);

  return accessControl.address;
}

export { deployAccessControl };
