import { deployAccessControl } from "./deploy-access-control";
import { deployTokenPrice } from "./deploy-oracle";
import { deployDiamond } from "./deploy-diamond";

async function deployMaster() {
  const accessControlAddress = await deployAccessControl();
  const tokenPriceAddress = await deployTokenPrice(accessControlAddress);
  await deployDiamond(tokenPriceAddress);
}

deployMaster()
  .then()
  .catch((error) => {
    console.error(error);
  });
