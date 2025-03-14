const hre = require("hardhat");

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineRouter01ABI=require("../artifacts/contracts/helper/VineRouter01.sol/VineRouter01.json");
const VineAaveV3LendMainABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain.sol/VineAaveV3LendMain.json");
const VineAaveV3LendMainFactoryABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMainFactory.sol/VineAaveV3LendMainFactory.json");
const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const Set=require('../set.json');
const { multicall } = require('@wagmi/core');

//router: 0x324ce268d413cC0F98cE42bF14E8A7c42dcd17DD
async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("manager:", manager.address);
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    const arbUSDC="0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d";
    const aavePool="0xBfC91D59fdAA134A4ED45f7B584cAf96D7792Eff";
    const arbGovernance="0xA2B4bA7eE9892ca980753338eB7bA655Bc5Ca66a";
    const vineAaveV3LendMainFactoryAddress="0x1af2739524265B986A0c48f436F1396FcDc69812";

    const Governance=new ethers.Contract(arbGovernance, GovernanceABI.abi, owner);
    const getMarketInfo=await Governance.getMarketInfo(0n);
    console.log("getMarketInfo:", getMarketInfo);

    const VineRouter01Address="0x324ce268d413cC0F98cE42bF14E8A7c42dcd17DD";
    const VineRouter01=new ethers.Contract(VineRouter01Address, VineRouter01ABI.abi, owner);

    const vineAaveV3LendMainFactory=new ethers.Contract(vineAaveV3LendMainFactoryAddress, VineAaveV3LendMainFactoryABI.abi, owner);
    const market = await vineAaveV3LendMainFactory.getUserIdToHook(0n);
    console.log("Market:", market);

    const ERC20Contract=new ethers.Contract(arbUSDC, ERC20ABI.abi, owner);
    const marketContract = new ethers.Contract(market, VineAaveV3LendMainABI.abi, owner);

    const getUserShareTokenBalance=await VineRouter01.getUserTokenBalance(market, owner.address);
    console.log("getUserShareTokenBalance:", getUserShareTokenBalance);

    const getUserSupplyToHookAmount=await VineRouter01.getUserSupplyToHookAmount(market, owner.address);
    console.log("getUserSupplyToHookAmount:", getUserSupplyToHookAmount);

    const getMarketTotalSupply=await VineRouter01.getMarketTotalSupply(market);
    console.log("getMarketTotalSupply:", getMarketTotalSupply);

    const getMarketTotalDepositeAmount=await VineRouter01.getMarketTotalDepositeAmount(market);
    console.log("getMarketTotalDepositeAmount:", getMarketTotalDepositeAmount);

    const getUserFinallyAmount=await VineRouter01.getUserFinallyAmount(0n, VineRouter01Address);
    console.log("getUserFinallyAmount:", getUserFinallyAmount);

    const getFeeData=await VineRouter01.getFeeData(0n);
    console.log("getFeeData:", getFeeData);

    
    const getUserTokenBalance=await VineRouter01.getUserTokenBalance(arbUSDC, market);
    console.log("getUserTokenBalance:", getUserTokenBalance);




}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});