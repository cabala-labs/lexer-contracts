const pairs = {
  1: "USDC/USD",
  2: "WETH/USD",
  3: "WBTC/USD",
  4: "EUR/USD",
  5: "GBP/JPY",
};

const findPairIndex = (pair: string) => {
  const index = Object.values(pairs).findIndex((p) => p === pair);
  return index + 1;
};

export { pairs, findPairIndex };
