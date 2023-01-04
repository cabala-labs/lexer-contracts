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
    sapphireTradeOrderAddress,
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
    emeraldTradeOrderAddress,
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
    sapphireTradeOrderAddress,
    emeraldTokenAddress,
    emeraldPoolAddress,
    emeraldTradeAddress,
    emeraldRewardAddress,
    emeraldTradeOrderAddress,
  };

  console.log(JSON.stringify(contractAddresses, null, 2));
  fs.writeFileSync(
    __dirname + "/../lexer-address.json",
    JSON.stringify(contractAddresses, null, 2)
  );

  // output a env format
  const env = `
  ADDRESS_ACCESS_CONTROL=${accessControlAddress}
  ADDRESS_ATM=${atmAddress}
  ADDRESS_SIMPLE_PRICE_FEED=${simplePriceFeedAddress}
  ADDRESS_REFERRAL=${referralAddress}
  ADDRESS_TOKEN_LIBS=${tokenLibsAddress}
  ADDRESS_SAPPHIRE_TOKEN=${sapphireTokenAddress}
  ADDRESS_SAPPHIRE_POOL=${sapphirePoolAddress}
  ADDRESS_SAPPHIRE_TRADE=${sapphireTradeAddress}
  ADDRESS_SAPPHIRE_REWARD=${sapphireRewardAddress}
  ADDRESS_SAPPHIRE_TRADE_ORDER=${sapphireTradeOrderAddress}
  ADDRESS_EMERALD_TOKEN=${emeraldTokenAddress}
  ADDRESS_EMERALD_POOL=${emeraldPoolAddress}
  ADDRESS_EMERALD_TRADE=${emeraldTradeAddress}
  ADDRESS_EMERALD_REWARD=${emeraldRewardAddress}
  ADDRESS_EMERALD_TRADE_ORDER=${emeraldTradeOrderAddress}
  `;
  console.log(env);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
