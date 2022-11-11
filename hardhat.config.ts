import { HardhatUserConfig, subtask } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-tracer";
import { ethers } from "hardhat";
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from "hardhat/builtin-tasks/task-names";

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(
  async (_, __, runSuper) => {
    const paths = await runSuper();

    return paths.filter((p: any) => !p.includes("ignore"));
  }
);

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // mainnet: {},
    goerli: {
      url: process.env.GOERLI_URL as string,
      // url: "https://goerli.infura.io/v3/1175d7a914d241fdb6f4f2086fb07be1",
      accounts: [process.env.PRIVATE_KEY as string],
      gasPrice: 12000000000,
    },
    hardhat: {},
    ganache: {
      url: "http://127.0.0.1:7545",
    },
    arb_goerli: {
      url: process.env.ARB_GOERLI_URL as string,
      accounts: [process.env.PRIVATE_KEY as string],
    },
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
