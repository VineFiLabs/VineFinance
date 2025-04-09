const hre = require("hardhat");
const fs = require("fs");
const ERC20ABI = require("../../artifacts/contracts/TestToken.sol/TestToken.json");
const VineHookCenterABI = require("../../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineCompoundFactoryABI = require("../../artifacts/contracts/hook/compound/VineCompoundFactory.sol/VineCompoundFactory.json");
const Set = require("../../set.json");

async function main() {
  const [owner, manager, testUser1, testUser3, testUser4] =
    await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  console.log("testUser1:", testUser1.address);
  console.log("testUser3:", testUser3.address);
  console.log("testUser4:", testUser4.address);

  let currentUser = manager;

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

  const VineHookCenter = new ethers.Contract(
    config.Deployed.VineHookCenter,
    VineHookCenterABI.abi,
    currentUser
  );

  const VineCompoundFactory = new ethers.Contract(
    config.Deployed.VineCompoundFactory,
    VineCompoundFactoryABI.abi,
    currentUser
  );
  const createCompoundMarket = await VineCompoundFactory.createCompoundMarket(
    manager.address,
    manager.address
  );
  const createCompoundMarketTx = await createCompoundMarket.wait();
  console.log("createCompoundMarket tx:", createCompoundMarketTx.hash);

  const lastId = await VineHookCenter.ID();
  const currentId = lastId -1n
  console.log("currentId:", currentId);

  const getCuratorId = await VineHookCenter.getCuratorId(
    currentUser.address
  );
  console.log("getCuratorId:", getCuratorId);

  const getUserIdToHook = await VineCompoundFactory.CuratorIdToHookMarketInfo(
    getCuratorId
  );
  console.log("Compound hook:", getUserIdToHook);
  

  config.Deployed[`VineCompoundHook${getCuratorId}`] = getUserIdToHook[1];

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
