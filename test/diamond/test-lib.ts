import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { DiamondTrade } from "../../typechain";
import {
  AccessControl,
  Diamond,
  DiamondPool,
  DiamondSwap,
  MockToken,
  TokenPrice,
} from "../../typechain";

async function deployContract(deployRequired?: { swap?: boolean; trade?: boolean }) {
  const AccessControlFactory = await ethers.getContractFactory("AccessControl");
  const accessControl = await AccessControlFactory.deploy();
  await accessControl.deployed();

  const TokenPriceFactory = await ethers.getContractFactory("TokenPrice");
  const tokenPrice = await TokenPriceFactory.deploy(accessControl.address);
  await tokenPrice.deployed();

  const TokenLibs = await ethers.getContractFactory("TokenLibs");
  const tokenLibs = await TokenLibs.deploy();
  await tokenLibs.deployed();

  const DiamondFactory = await ethers.getContractFactory("Diamond");
  const diamond = await DiamondFactory.deploy();
  await diamond.deployed();

  const DiamondPoolFactory = await ethers.getContractFactory("DiamondPool", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const diamondPool = await DiamondPoolFactory.deploy(diamond.address, tokenPrice.address);
  await diamondPool.deployed();

  let diamondSwap: DiamondSwap | undefined;
  if (deployRequired?.swap) {
    const DiamondSwapFactory = await ethers.getContractFactory("DiamondSwap", {
      libraries: {
        TokenLibs: tokenLibs.address,
      },
    });
    diamondSwap = await DiamondSwapFactory.deploy(diamondPool.address, tokenPrice.address);
    await diamondSwap.deployed();
  }
  let diamondTrade: DiamondTrade | undefined;
  if (deployRequired?.trade) {
    const DiamondFactoryTrade = await ethers.getContractFactory("DiamondTrade", {
      libraries: {
        tokenLibs: tokenLibs.address,
      },
    });
    diamondTrade = await DiamondFactoryTrade.deploy(diamondPool.address, tokenPrice.address);
    await diamondTrade.deployed();
  }

  return {
    diamond,
    diamondPool,
    tokenPrice,
    accessControl,
    diamondSwap,
    diamondTrade,
  };
}

async function deployMockToken(deployRequired: {
  usdc?: boolean;
  euroc?: boolean;
  weth?: boolean;
}) {
  let usdc: MockToken | undefined;
  if (deployRequired.usdc) {
    const USDC = await ethers.getContractFactory("MockToken");
    usdc = await USDC.deploy("USDC", "USDC", 6);
    await usdc.deployed();
  }

  let euroc: MockToken | undefined;
  if (deployRequired.euroc) {
    const EUROC = await ethers.getContractFactory("MockToken");
    euroc = await EUROC.deploy("EUROC", "EUROC", 6);
    await euroc.deployed();
  }

  let weth: MockToken | undefined;
  if (deployRequired.weth) {
    const WETH = await ethers.getContractFactory("MockToken");
    weth = await WETH.deploy("WETH", "WETH", 18);
    await weth.deployed();
  }

  return { usdc, euroc, weth };
}

async function initializePool(pool: DiamondPool, token: MockToken, amount?: BigNumber) {
  if (!amount) {
    const decimals = await token.decimals();
    amount = BigNumber.from(100000).mul(BigNumber.from(10).pow(decimals));
  }
  await token.mint(pool.address, amount);
}

async function listTokenInOracle(tokenPrice: TokenPrice, token: MockToken) {
  await tokenPrice.addToken(token.address);
}

async function getMockToken(token: MockToken, to: SignerWithAddress, amount: BigNumber) {
  await token.mint(to.address, amount);
}

async function setLatestPrice(
  tokenPrice: TokenPrice,
  token: MockToken,
  amount: BigNumber | number
) {
  // const tokenDecimal = await token.decimals();
  amount = BigNumber.from(amount).mul(BigNumber.from(10).pow(8));
  await tokenPrice.setLatestPrice(token.address, amount);
}

async function swapToken(
  swapContract: DiamondSwap,
  tokenIn: MockToken,
  amountIn: BigNumber,
  tokenOut: MockToken,
  minAmountOut: BigNumber
) {
  try {
    await swapContract.placeSwapOrder(tokenIn.address, amountIn, tokenOut.address, minAmountOut);
  } catch (error) {
    console.log(error);
  }
}

async function stakeERC20(
  account: SignerWithAddress,
  diamondPool: DiamondPool,
  token: MockToken,
  amount: BigNumber | number
) {
  await diamondPool.buyDiamond(account.address, token.address, amount);
}

async function approveToken(account: SignerWithAddress, contract: string, token: MockToken) {
  await token.approve(contract, ethers.constants.MaxUint256, { from: account.address });
}

// todo use parseUnits instead of BigNumber calculation
async function toTokenDecimal(token: MockToken | Diamond, amount: BigNumber | number) {
  const tokenDecimal = await token.decimals();
  amount = BigNumber.from(amount).mul(BigNumber.from(10).pow(tokenDecimal));
  return amount;
}

async function toDecimal(amount: BigNumber | number, targetDecimal: number, token?: MockToken) {
  if (!token) {
    return BigNumber.from(amount).mul(BigNumber.from(10).pow(targetDecimal));
  }
  const tokenDecimal = await token.decimals();
  const decimalDifference = Math.abs(tokenDecimal - targetDecimal);
  if (tokenDecimal > targetDecimal) {
    return BigNumber.from(amount).div(BigNumber.from(10).pow(decimalDifference));
  }
  if (tokenDecimal < targetDecimal) {
    return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimalDifference));
  }
  return BigNumber.from(amount);
}

async function grantRight(accessControl: AccessControl, role: string, account: SignerWithAddress) {
  await accessControl.grantRole(account.address, role);
}

async function createPosition(
  diamondTrade: DiamondTrade,
  collateralToken: MockToken,
  amount: BigNumber,
  indexToken: MockToken,
  positionSize: BigNumber,
  tradeType: 0 | 1
) {
  await diamondTrade.createPostion(
    collateralToken.address,
    amount,
    indexToken.address,
    positionSize,
    tradeType
  );
}

export {
  createPosition,
  deployContract,
  deployMockToken,
  initializePool,
  swapToken,
  getMockToken,
  listTokenInOracle,
  setLatestPrice,
  toTokenDecimal,
  toDecimal,
  grantRight,
  approveToken,
  stakeERC20,
};
