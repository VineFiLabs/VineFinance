const hre = require("hardhat");
const fs = require("fs");
const ERC20ABI = require("../../artifacts/contracts/TestToken.sol/TestToken.json");
const VineHookCenterABI = require("../../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineMorphoFactoryABI = require("../../artifacts/contracts/hook/morpho/VineMorphoFactory.sol/VineMorphoFactory.json");
const VineMorphoHookABI = require("../../artifacts/contracts/hook/morpho/VineMorphoCore.sol/VineMorphoCore.json");
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

  const register = await VineHookCenter.register(
    0,
    config.Domain,
    [Set["Avalanche_fuji"].Domain, Set["Arbitrum_Sepolia"].Domain, Set["Base_Sepolia"].Domain, Set["Op_Sepolia"].Domain]
  );
  const registerTx = await register.wait();
  console.log("register success:", registerTx.hash);

  const VineMorphoFactory = new ethers.Contract(
    config.Deployed.VineMorphoFactory,
    VineMorphoFactoryABI.abi,
    currentUser
  );
  const createMorphoMarket = await VineMorphoFactory.createMorphoMarket(
    manager.address,
    manager.address
  );
  const createMorphoMarketTx = await createMorphoMarket.wait();
  console.log("createMorphoMarket tx:", createMorphoMarketTx.hash);

  const baseMorphoMarket = "0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb";

  const lastId = await VineHookCenter.ID();
  const currentId = lastId -1n
  console.log("currentId:", currentId);

  const getCuratorId = await VineHookCenter.getCuratorId(
    currentUser.address
  );
  console.log("getCuratorId:", getCuratorId);

  const getUserIdToHook = await VineMorphoFactory.CuratorIdToHookMarketInfo(
    getCuratorId
  );
  console.log("Morpho hook:", getUserIdToHook);

  const VineMorphoHook = new ethers.Contract(
    getUserIdToHook[1],
    VineMorphoHookABI.abi,
    manager
  );
  const thisManager = await VineMorphoHook.manager();
  console.log("thisManager:", thisManager);

  const thisOwner = await VineMorphoHook.owner();
  console.log("thisOwner:", thisOwner);

  const ID =
    "0xe36464b73c0c39836918f7b2b9a6f1a8b70d7bb9901b38f29544d9b96119862e";
  const getPosition = await VineMorphoHook.getPosition(ID, currentUser, baseMorphoMarket);
  console.log("getPosition:", getPosition);

  const marketParams = await VineMorphoHook.getIdToMarketParams(ID, baseMorphoMarket);
  console.log("marketParams:", marketParams);

  const MarketParams = {
    loanToken: marketParams[0],
    collateralToken: marketParams[1],
    oracle: marketParams[2],
    irm: marketParams[3],
    lltv: marketParams[4],
  };

  // const withdraw = await VineMorphoHook.withdraw(
  //   MarketParams,
  //   0,
  //   10000n,
  //   0
  // );
  // const withdrawTx = await withdraw.wait();
  // console.log("withdraw:", withdrawTx.hash);

  config.Deployed[`VineMorphoHook${getCuratorId}`] = getUserIdToHook[1];

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
