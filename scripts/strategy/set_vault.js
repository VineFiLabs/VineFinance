const hre = require("hardhat");

const VineHookCenterABI = require("../../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const GovernanceABI = require("../../artifacts/contracts/core/Governance.sol/Governance.json");
const CoreCrossCenterABI = require("../../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const CrossCenterABI = require("../../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const VineVaultCoreFactoryABI = require("../../artifacts/contracts/core/VineVaultCoreFactory.sol/VineVaultCoreFactory.json");
const VineVaultFactoryABI = require("../../artifacts/contracts/core/VineVaultFactory.sol/VineVaultFactory.json");
const Set = require("../../set.json");

async function main() {
  const [owner, manager, testUser1, testUser3, testUser4] =
    await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  console.log("testUser1:", testUser1.address);
  console.log("testUser3:", testUser3.address);
  console.log("testUser4:", testUser4.address);

  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

  let currentUser = manager;
  const marketId = 5;
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
      marketId,
      config.Deployed.VineAaveV3LendMain02Hook0
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

  const marketInfo = await GovernanceContract.getMarketInfo(marketId);
  console.log("marketInfo:", marketInfo);

  //max-aave
  // const avaxBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Avalanche_fuji"].Deployed.VineAaveV3LendMain02Hook0
  // );
  // console.log("avaxBytes32Market:", avaxBytes32Market);
  // const opBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Op_Sepolia"].Deployed.VineInL2LendHook0
  // );
  // console.log("opBytes32Market:", opBytes32Market);
  // const arbBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Arbitrum_Sepolia"].Deployed.VineInL2LendHook0
  // );
  // console.log("arbBytes32Market:", arbBytes32Market);
  // const baseBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Base_Sepolia"].Deployed.VineInL2LendHook0
  // );
  // console.log("baseBytes32Market:", baseBytes32Market);

  // //vault
  // const avaxBytes32Vault = await CrossCenterContract.addressToBytes32(
  //   Set["Avalanche_fuji"].Deployed[`VineVault${marketId}`]
  // );
  // console.log("avaxBytes32Vault:", avaxBytes32Vault);
  // const opBytes32Vault = await CrossCenterContract.addressToBytes32(
  //   Set["Op_Sepolia"].Deployed[`VineVault${marketId}`]
  // );
  // console.log("opBytes32Vault:", opBytes32Vault);
  // const arbBytes32Vault = await CrossCenterContract.addressToBytes32(
  //   Set["Arbitrum_Sepolia"].Deployed[`VineVault${marketId}`]
  // );
  // console.log("arbBytes32Vault:", arbBytes32Vault);
  // const baseBytes32Vault = await CrossCenterContract.addressToBytes32(
  //   Set["Base_Sepolia"].Deployed[`VineVault${marketId}`]
  // );
  // console.log("baseBytes32Vault:", baseBytes32Vault);

  // const avaxBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   marketId,
  //   1,
  //   avaxBytes32Vault,
  //   [avaxBytes32Market]
  // );
  // await avaxBatchSetValidHooks.wait();
  // console.log("avaxBatchSetValidHooks success");
  // const opBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   marketId,
  //   2,
  //   opBytes32Vault,
  //   [opBytes32Market]
  // );
  // await opBatchSetValidHooks.wait();
  // console.log("opBatchSetValidHooks success");
  // const arbBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   marketId,
  //   3,
  //   arbBytes32Vault,
  //   [arbBytes32Market]
  // );
  // await arbBatchSetValidHooks.wait();
  // console.log("arbBatchSetValidHooks success");
  // const baseBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   marketId,
  //   6,
  //   baseBytes32Vault,
  //   [baseBytes32Market]
  // );
  // await baseBatchSetValidHooks.wait();
  // console.log("baseBatchSetValidHooks success");

  //aave-morpho
  // const avaxBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Avalanche_fuji"].Deployed.VineAaveV3LendMain02Hook0
  // );
  // console.log("avaxBytes32Market:", avaxBytes32Market);
  // const baseBytes32Market = await CrossCenterContract.addressToBytes32(
  //   Set["Base_Sepolia"].Deployed.VineMorphoHook0
  // );
  // console.log("baseBytes32Market:", baseBytes32Market);

  // //vault
  // const avaxBytes32Vault = await CrossCenterContract.addressToBytes32(
  //   Set["Avalanche_fuji"].Deployed[`VineVault${marketId}`]
  // );
  // console.log("avaxBytes32Vault:", avaxBytes32Vault);
  // const baseBytes32Vault = await CrossCenterContract.addressToBytes32(
  //   Set["Base_Sepolia"].Deployed[`VineVault${marketId}`]
  // );
  // console.log("baseBytes32Vault:", baseBytes32Vault);

  // const avaxBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   marketId,
  //   1,
  //   avaxBytes32Vault,
  //   [avaxBytes32Market]
  // );
  // await avaxBatchSetValidHooks.wait();
  // console.log("avaxBatchSetValidHooks success");

  // const baseBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
  //   marketId,
  //   6,
  //   baseBytes32Vault,
  //   [baseBytes32Market]
  // );
  // await baseBatchSetValidHooks.wait();
  // console.log("baseBatchSetValidHooks success");

  //aave-compound
  const avaxBytes32Market = await CrossCenterContract.addressToBytes32(
    Set["Avalanche_fuji"].Deployed.VineAaveV3LendMain02Hook0
  );
  console.log("avaxBytes32Market:", avaxBytes32Market);
  const baseBytes32Market = await CrossCenterContract.addressToBytes32(
    Set["Base_Sepolia"].Deployed.VineCompoundHook0
  );
  console.log("baseBytes32Market:", baseBytes32Market);

  //vault
  const avaxBytes32Vault = await CrossCenterContract.addressToBytes32(
    Set["Avalanche_fuji"].Deployed[`VineVault${marketId}`]
  );
  console.log("avaxBytes32Vault:", avaxBytes32Vault);
  const baseBytes32Vault = await CrossCenterContract.addressToBytes32(
    Set["Base_Sepolia"].Deployed[`VineVault${marketId}`]
  );
  console.log("baseBytes32Vault:", baseBytes32Vault);

  const avaxBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
    marketId,
    1,
    avaxBytes32Vault,
    [avaxBytes32Market]
  );
  await avaxBatchSetValidHooks.wait();
  console.log("avaxBatchSetValidHooks success");

  const baseBatchSetValidHooks = await GovernanceContract.batchSetValidHooks(
    marketId,
    6,
    baseBytes32Vault,
    [baseBytes32Market]
  );
  await baseBatchSetValidHooks.wait();
  console.log("baseBatchSetValidHooks success");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
