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


  const VineUniswapV3FactoryAddress="0xe85977d510e23A9f8dAab1799f2fB0940B86aF11";
  const VineUniswapV3Factory=new ethers.Contract(VineUniswapV3FactoryAddress, VineUniswapV3FactoryABI.abi, manager);

  const VineUniswapHookAddress = await VineUniswapV3Factory.getUserIdToHook(3n);
  console.log("VineUniswapHookAddress address:", VineUniswapHookAddress);

  const arbUSDC = "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d";
  const arbAUSDC = "0x460b97BD498E1157530AEb3086301d5225b91216";
  const arbWETH = "0x1dF462e2712496373A347f8ad10802a5E95f053D";
  const arbWETHVToken = "0x372eB464296D8D78acaa462b41eaaf2D3663dAD3";
  const arbWrappedTokenGateway = "0x20040a64612555042335926d72B4E5F667a67fA1";
  const arbL2Encode = "0x2E45e7dCD1e94d8edf1605FfF4602912FDC662bC";
  const arbPool = "0xBfC91D59fdAA134A4ED45f7B584cAf96D7792Eff";

  const VineUniswapHook=new ethers.Contract(VineUniswapHookAddress, VineUniswapV3CoreABI.abi, manager);
  const borrowAmount=ethers.parseEther("0.0000001");
//   const inL2Borrow=await VineUniswapHook.inL2Borrow(
//     arbWETH,
//     arbWETHVToken,
//     arbWrappedTokenGateway,
//     arbPool,
//     borrowAmount,
//     2
//   );
//   const inL2BorrowTx=await inL2Borrow.wait();
//   console.log("inL2Borrow Tx:", inL2BorrowTx.hash);

  const v3Swap=await VineUniswapHook.v3Swap();
  const v3SwapTx=await v3Swap.wait();
  console.log("v3Swap tx:", v3SwapTx.hash);


}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
