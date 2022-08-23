import { ethers } from "hardhat";

async function addRole() {
  const AccessControl = await ethers.getContractFactory("AccessControl");
  const accessControl = await AccessControl.attach("0x3ce4C0cEd7dbbe3177A594a1d933466d1fCAa0A0");

  // convert string to bytes32
  //   const role = ethers.utils.formatBytes32String("TokenPrice_Keeper");
  const role = ethers.utils.id("TokenPrice_Feeder");
  //   accessControl.grantRole("0x32DA7b2C51555e5E98B204bb6A3f77f1469231a1", role);
  accessControl.grantRole("0x3d88835d2460d28Ff0A0D8478B0B461287De94C2", role);
}

addRole()
  .then()
  .catch((error) => {
    console.error(error);
  });
