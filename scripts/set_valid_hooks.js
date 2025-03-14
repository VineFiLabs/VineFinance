const hre = require("hardhat");

const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const CoreCrossCenterABI = require("../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const CrossCenterABI = require("../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const Set = require("../set.json");

async function main() {
  const [owner, manager, testUser1, testUser3, testUser4] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  console.log("testUser1:", testUser1.address);
  console.log("testUser3:", testUser3.address);
  console.log("testUser4:", testUser4.address);

  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

  let currentUser = testUser3;
  console.log("currentUser:", currentUser.address);

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

  let CrossCenterContract;
  let GovernanceContract;
  // if(chainId === 43113n){
  //     CrossCenterContract=new ethers.Contract(config.Deployed.CoreCrossCenter, CoreCrossCenterABI.abi, manager);
  //     GovernanceContract=new ethers.Contract(config.Deployed.Governance, GovernanceABI.abi, manager);

  //     const initialize = await GovernanceContract.initialize(config.Deployed.VineAaveV3LendMain02Hook);
  //     await initialize.wait();
  //     console.log("initialize success");
  // }else{
  //     CrossCenterContract=new ethers.Contract(config.Deployed.CrossCenter, CrossCenterABI.abi, manager);
  //     GovernanceContract=new ethers.Contract(config.Deployed.VineHookCenter, VineHookCenterABI.abi, manager);
  // }
  if (chainId === 43113n) {
    CrossCenterContract = new ethers.Contract(
      config.Deployed.CoreCrossCenter,
      CoreCrossCenterABI.abi,
      currentUser
    );
    GovernanceContract = new ethers.Contract(
      config.Deployed.Governance,
      GovernanceABI.abi,
      currentUser
    );

    const initialize = await GovernanceContract.initialize(
      config.Deployed.VineAaveV3LendMain02Hook2
    );
    const initializeTx = await initialize.wait();
    console.log("initialize success:", initializeTx.hash);
  } else {
    CrossCenterContract = new ethers.Contract(
      config.Deployed.CrossCenter,
      CrossCenterABI.abi,
      currentUser
    );
    GovernanceContract = new ethers.Contract(
      config.Deployed.VineHookCenter,
      VineHookCenterABI.abi,
      currentUser
    );
  }

  // const marketInfo = await GovernanceContract.getMarketInfo(2);
  // console.log("marketInfo:", marketInfo);

  const getCuratorToId = await GovernanceContract.getCuratorToId(
    currentUser.address
  );
  console.log("getCuratorToId:", getCuratorToId);

  const marketInfo=await GovernanceContract.getMarketInfo(getCuratorToId);
  console.log("marketInfo:", marketInfo);

  //max-aave
  // const avaxBytes32Market = await CrossCenterContract.addressToBytes32(Set["Avalanche_fuji"].Deployed.VineAaveV3LendMain02Hook0);
  // console.log("avaxBytes32Market:", avaxBytes32Market);
  // const opBytes32Market = await CrossCenterContract.addressToBytes32(Set["Op_Sepolia"].Deployed.VineInL2LendHook0);
  // console.log("opBytes32Market:", opBytes32Market);
  // const arbBytes32Market = await CrossCenterContract.addressToBytes32(Set["Arbitrum_Sepolia"].Deployed.VineInL2LendHook0);
  // console.log("arbBytes32Market:", arbBytes32Market);
  // const baseBytes32Market = await CrossCenterContract.addressToBytes32(Set["Base_Sepolia"].Deployed.VineInL2LendHook0);
  // console.log("baseBytes32Market:", baseBytes32Market);

  // const avaxBatchSetValidHooks=await GovernanceContract.batchSetValidHooks(1, [avaxBytes32Market]);
  // await avaxBatchSetValidHooks.wait();
  // console.log("avaxBatchSetValidHooks success");
  // const opBatchSetValidHooks=await GovernanceContract.batchSetValidHooks(2, [opBytes32Market]);
  // await opBatchSetValidHooks.wait();
  // console.log("opBatchSetValidHooks success");
  // const arbBatchSetValidHooks=await GovernanceContract.batchSetValidHooks(3, [arbBytes32Market]);
  // await arbBatchSetValidHooks.wait();
  // console.log("arbBatchSetValidHooks success");
  // const baseBatchSetValidHooks=await GovernanceContract.batchSetValidHooks(6, [baseBytes32Market]);
  // await baseBatchSetValidHooks.wait();
  // console.log("baseBatchSetValidHooks success");

  //aave-morpho
  const avaxBytes32Market = await CrossCenterContract.addressToBytes32(Set["Avalanche_fuji"].Deployed.VineAaveV3LendMain02Hook2);
  console.log("avaxBytes32Market:", avaxBytes32Market);
  const baseBytes32Market = await CrossCenterContract.addressToBytes32(Set["Base_Sepolia"].Deployed.VineMorphoHook2);
  console.log("baseBytes32Market:", baseBytes32Market);

  const avaxBatchSetValidHooks=await GovernanceContract.batchSetValidHooks(1, [avaxBytes32Market]);
  await avaxBatchSetValidHooks.wait();
  console.log("avaxBatchSetValidHooks success");
  const baseBatchSetValidHooks=await GovernanceContract.batchSetValidHooks(6, [baseBytes32Market]);
  await baseBatchSetValidHooks.wait();
  console.log("baseBatchSetValidHooks success");


  // const avaxBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Avalanche_fuji"].Deployed.VineAaveV3LendMain02Hook3
  // );
  // console.log("avaxBytes32Market:", avaxBytes32Market);
  // const arbBytes32UniswapHook = await CrossCenterContract.addressToBytes32(
  //   Set["Arbitrum_Sepolia"].Deployed.VineUniswapHook2
  // );
  // console.log("arbBytes32UniswapHook:", arbBytes32UniswapHook);

  // const avaxBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   1,
  //   [avaxBytes32Market]
  // );
  // await avaxBatchSetValidHooks.wait();
  // console.log("avaxBatchSetValidHooks success");
  // const arbBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(3, [
  //   arbBytes32UniswapHook,
  // ]);
  // await arbBatchSetValidHooks.wait();
  // console.log("arbBatchSetValidHooks success");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
