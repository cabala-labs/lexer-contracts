const pairs = {
  1: "USDC/USD",
  2: "ETH/USD",
  3: "BTC/USD",
  4: "EUR/USD",
  5: "GBP/JPY",
};

const findPairIndex = (pair: string) => {
  const index = Object.values(pairs).findIndex((p) => p === pair);
  return index + 1;
};

export { pairs, findPairIndex };
