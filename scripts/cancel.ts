import { ethers } from "hardhat";

async function main() {
  const gasPrice = await ethers.provider.getGasPrice();
  console.log(gasPrice);
  const signer = (await ethers.getSigners())[0];
  console.log("signer", signer.address);
  const nonce = await ethers.provider.getTransactionCount(
    signer.address,
    "latest"
  );
  console.log("nonce", nonce);
  const cancelTx = {
    from: signer.address,
    to: signer.address,
    gasPrice: 50000000000,
    // gasLimit: ethers.utils.hexlify(100000),
    value: ethers.utils.parseEther("0.001"),
    nonce: nonce,
  };
  const tx = await signer.sendTransaction(cancelTx);
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
