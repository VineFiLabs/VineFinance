const hre = require("hardhat");
const fs = require("fs");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineMorphoFactoryABI = require("../artifacts/contracts/hook/morpho/VineMorphoFactory.sol/VineMorphoFactory.json");
const VineMorphoHookABI = require("../artifacts/contracts/hook/morpho/VineMorphoCore.sol/VineMorphoCore.json");
const MorphoAdaptiveCurveIrmABI = require("../json/MorphoAdaptiveCurveIrm.json");
const MorphoABI = require("../json/Morpho.json");
const Set = require("../set.json");

async function main() {
  const [owner, manager, testUser1, testUser3, testUser4] =
    await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  console.log("testUser1:", testUser1.address);
  console.log("testUser3:", testUser3.address);
  console.log("testUser4:", testUser4.address);

  let currentUser = testUser3;

  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

  async function sendETH(toAddress, amountInEther) {
    const amountInWei = ethers.parseEther(amountInEther);
    const tx = {
      to: toAddress,
      value: amountInWei,
    };
    const transactionResponse = await owner.sendTransaction(tx);
    await transactionResponse.wait();
    console.log("Transfer eth success");
  }

  // await sendETH(currentUser.address, "0.03");

  let config;
  let networkName;
  if (chainId === 1n) {
    config = Set.Ethereum_Mainnet;
    networkName = "Ethereum_Mainnet";
  } else if (chainId === 43114n) {
    config = Set.Avalanche_Mainnet;
    networkName = "Avalanche_Mainnet";
  } else if (chainId === 10n) {
    config = Set.Op_Mainnet;
    networkName = "Op_Mainnet";
  } else if (chainId === 42161n) {
    config = Set.Arbitrum_Mainnet;
    networkName = "Arbitrum_Mainnet";
  } else if (chainId === 8453n) {
    config = Set.Base_Mainnet;
    networkName = "Base_Mainnet";
  } else if (chainId === 11155111n) {
    config = Set.Sepolia;
    networkName = "Sepolia";
  } else if (chainId === 43113n) {
    config = Set.Avalanche_fuji;
    networkName = "Avalanche_fuji";
  } else if (chainId === 11155420n) {
    config = Set.Op_Sepolia;
    networkName = "Op_Sepolia";
  } else if (chainId === 421614n) {
    config = Set.Arbitrum_Sepolia;
    networkName = "Arbitrum_Sepolia";
  } else if (chainId === 84532n) {
    config = Set.Base_Sepolia;
    networkName = "Base_Sepolia";
  } else {
    throw "Not chain id";
  }


  const ID =
    "0x320de559d8aa4b618457efc1dcd8587c5e43a89ab922bac7729abf21c5b1db2e";
  const morphoMarketAddress = "0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb";
    const MorphoMarket = new ethers.Contract(morphoMarketAddress, MorphoABI, owner);

  const marketParams = await MorphoMarket.idToMarketParams(ID);
  console.log("marketParams:", marketParams);

  const MarketParams = {
    loanToken: marketParams[0],
    collateralToken: marketParams[1],
    oracle: marketParams[2],
    irm: marketParams[3],
    lltv: marketParams[4],
  };

  const getMarket = await MorphoMarket.market(ID);
  console.log("getMarket:", getMarket);

  const Market = {
    totalSupplyAssets: getMarket[0],
    totalSupplyShares: getMarket[1],
    totalBorrowAssets: getMarket[2],
    totalBorrowShares: getMarket[3],
    lastUpdate: getMarket[4],
    fee: getMarket[5],
  };

  const MorphoAdaptiveCurveIrmAddress = "0x46415998764C29aB2a25CbeA6254146D50D22687";
  const MorphoAdaptiveCurveIrm = new ethers.Contract(
    MorphoAdaptiveCurveIrmAddress,
    MorphoAdaptiveCurveIrmABI,
    owner
  );

  const borrowRate = await MorphoAdaptiveCurveIrm.borrowRateView(
    MarketParams,
    Market
  );
  console.log("borrowRate:", borrowRate);

  const utilization = getMarket[0] / getMarket[2];
  console.log("utilization:", utilization);

  const supplyAPY = borrowRate *  utilization * (1 - getMarket[5]);
  console.log("supplyAPY:", supplyAPY);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
