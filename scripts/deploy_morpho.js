const hre = require("hardhat");
const fs = require("fs");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const Set = require("../set.json");

// VineMorphoFactory address: 

async function main() {
  const [owner, manager, testUser, testUser3, testUser4] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  console.log("testUser:", testUser.address);
  console.log("testUser3:", testUser3.address);
  console.log("testUser4:", testUser4.address);


  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

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

  const vineMorphoFactory = await ethers.getContractFactory(
    "VineMorphoFactory"
  );
  const VineMorphoFactory = await vineMorphoFactory.deploy(
    config.Deployed.VineHookCenter
  );
  const VineMorphoFactoryAddress = VineMorphoFactory.target;
  console.log("VineMorphoFactory address:", VineMorphoFactoryAddress);
  config.Deployed.VineMorphoFactory = VineMorphoFactoryAddress;

  const baseMorphoMarket = "0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb";
  

  const setPath = "./set.json";
  const currentSet = JSON.parse(fs.readFileSync(setPath, "utf8"));
  currentSet[networkName] = config;
  fs.writeFileSync(setPath, JSON.stringify(currentSet, null, 2));
  console.log("set.json updated");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
