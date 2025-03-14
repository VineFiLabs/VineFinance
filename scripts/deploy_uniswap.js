const hre = require("hardhat");
const fs = require("fs");
const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const VineUniswapV3CoreABI = require("../artifacts/contracts/hook/uniswap/VineUniswapV3Core.sol/VineUniswapV3Core.json");
const VineUniswapV3FactoryABI = require("../artifacts/contracts/hook/uniswap/VineUniswapV3Factory.sol/VineUniswapV3Factory.json");
const Set = require("../set.json");

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

  const vineUniswapV3Factory = await ethers.getContractFactory(
    "VineUniswapV3Factory"
  );
  const VineUniswapV3Factory = await vineUniswapV3Factory.deploy(
    config.Deployed.VineHookCenter
  );
  const VineUniswapV3FactoryAddress = VineUniswapV3Factory.target;
  console.log("VineUniswapV3Factory address:", VineUniswapV3FactoryAddress);

  // const VineUniswapV3FactoryAddress="0x1397787197dcc325e1aDB55b9ae16b01FC6dfD99";
  const UserVineUniswapV3Factory=new ethers.Contract(VineUniswapV3FactoryAddress, VineUniswapV3FactoryABI.abi, testUser4);

  config.Deployed.VineUniswapV3Factory = VineUniswapV3FactoryAddress;

  const vineUniswapHook2 = await UserVineUniswapV3Factory.createUniSwapMarket(
    testUser4.address,
    manager.address
  );
  await vineUniswapHook2.wait();
  console.log("vineUniswapHook2 success");
  const VineUniswapHook2Address = await UserVineUniswapV3Factory.getUserIdToHook(3n);
  console.log("VineUniswapHook2Address address:", VineUniswapHook2Address);
  config.Deployed.VineUniswapHook2 = VineUniswapHook2Address;

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
