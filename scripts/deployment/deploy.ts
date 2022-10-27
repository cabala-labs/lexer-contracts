import deployPeripheral from "./deploy-peripheral";
import deploySapphire from "./deploy-sapphire";
import deployEmerald from "./deploy-emerald";
import fs from "fs";
async function main() {
  const {
    accessControlAddress,
    atmAddress,
    simplePriceFeedAddress,
    referralAddress,
    tokenLibsAddress,
  } = await deployPeripheral();

  const {
    sapphireTokenAddress,
    sapphirePoolAddress,
    sapphireTradeAddress,
    sapphireRewardAddress,
  } = await deploySapphire(
    accessControlAddress,
    atmAddress,
    simplePriceFeedAddress,
    referralAddress,
    tokenLibsAddress
  );

  const {
    emeraldTokenAddress,
    emeraldPoolAddress,
    emeraldTradeAddress,
    emeraldRewardAddress,
  } = await deployEmerald(
    accessControlAddress,
    atmAddress,
    simplePriceFeedAddress,
    referralAddress,
    tokenLibsAddress
  );

  const contractAddresses = {
    accessControlAddress,
    atmAddress,
    simplePriceFeedAddress,
    referralAddress,
    tokenLibsAddress,
    sapphireTokenAddress,
    sapphirePoolAddress,
    sapphireTradeAddress,
    sapphireRewardAddress,
    emeraldTokenAddress,
    emeraldPoolAddress,
    emeraldTradeAddress,
    emeraldRewardAddress,
  };

  console.log(JSON.stringify(contractAddresses, null, 2));
  fs.writeFileSync(
    __dirname + "/../lexer-address.json",
    JSON.stringify(contractAddresses, null, 2)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
