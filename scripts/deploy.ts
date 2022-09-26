import deployOracle from "./deploy-oracle";
import deploySapphire from "./deploy-sapphire";

async function main() {
  const { simplePriceFeedAddress } = await deployOracle();
  await deploySapphire(simplePriceFeedAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
