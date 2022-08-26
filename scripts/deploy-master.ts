import { deployAccessControl } from "./deploy-access-control";
import { deployTokenPrice } from "./deploy-oracle";
import { deployDiamond } from "./deploy-diamond";
import { deployLibraries } from "./deploy-libraries";

async function deployMaster() {
  const accessControlAddress = await deployAccessControl();
  const tokenPriceAddress = await deployTokenPrice(accessControlAddress);
  const libraryAddress = await deployLibraries();
  await deployDiamond(tokenPriceAddress, libraryAddress);
}

deployMaster()
  .then()
  .catch((error) => {
    console.error(error);
  });
