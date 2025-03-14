const hre = require("hardhat");

const VineHookCenterABI=require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineAaveL2ABI=require("../artifacts/contracts/hook/aave/VineAaveV3InL2Lend.sol/VineAaveV3InL2Lend.json");
const VineAaveV3LendMainFactoryABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain02Factory.sol/VineAaveV3LendMain02Factory.json");
const VineInL2LendFactoryABI=require("../artifacts/contracts/hook/aave/VineInL2LendFactory.sol/VineInL2LendFactory.json");
const VineAaveV3InL2LendABI=require("../artifacts/contracts/hook/aave/VineAaveV3InL2Lend.sol/VineAaveV3InL2Lend.json");
const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const CrossCenterABI=require("../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");

const Set=require('../set.json');

//router: 0x33FeCACBcd38C2D87DFA5c77Ac3656464e69eDD9
async function main() {
    const [owner, manager, testUser] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("manager:", manager.address);
    console.log("testUser:", testUser.address);
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    let config;
    let currentGovernanceABI;
    let networkName;
    let GovernanceAddress;
    if(chainId === 1n){
      config = Set.Ethereum_Mainnet;
      networkName = "Ethereum_Mainnet";
    }else if(chainId === 43114n){
      config = Set.Avalanche_Mainnet;
      networkName = "Avalanche_Mainnet";
    }else if(chainId === 10n){
      config = Set.Op_Mainnet;
      networkName = "Op_Mainnet";
    }else if(chainId === 42161n){
      config = Set.Arbitrum_Mainnet;
      networkName = "Arbitrum_Mainnet";
    }else if(chainId === 8453n){
      config = Set.Base_Mainnet;
      networkName = "Base_Mainnet";
    }else if(chainId === 11155111n){
      config = Set.Sepolia;
      networkName = "Sepolia";
    }else if(chainId === 43113n){ 
      config = Set.Avalanche_fuji;
      networkName = "Avalanche_fuji";
      currentGovernanceABI = GovernanceABI.abi;
      GovernanceAddress = config.Deployed.Governance;
    }else if(chainId === 11155420n){
      config = Set.Op_Sepolia;
      networkName = "Op_Sepolia";
      currentGovernanceABI = VineHookCenterABI.abi;
      GovernanceAddress = config.Deployed.VineHookCenter;
    }else if(chainId === 421614n){
      config = Set.Arbitrum_Sepolia;
      networkName = "Arbitrum_Sepolia";
      currentGovernanceABI = VineHookCenterABI.abi;
      GovernanceAddress = config.Deployed.VineHookCenter;
    }else if(chainId === 84532n){
      config = Set.Base_Sepolia;
      networkName = "Base_Sepolia";
      currentGovernanceABI = VineHookCenterABI.abi;
      GovernanceAddress = config.Deployed.VineHookCenter;
    }else{
      throw("Not chain id");
    }

    const Governance=new ethers.Contract(GovernanceAddress, currentGovernanceABI, manager);
    const getMarketInfo=await Governance.getMarketInfo(0n);
    console.log("getMarketInfo:", getMarketInfo);

    // const VineInL2LendFactory=new ethers.Contract(config.Deployed.VineInL2LendFactory, VineInL2LendFactoryABI.abi, manager);
    // const market = await VineInL2LendFactory.getUserIdToHook(1n);
    // console.log("Market:", market);

    const CrossCenter=new ethers.Contract(config.Deployed.CrossCenter,CrossCenterABI.abi,manager);

    const message = "0x000000000000000100000003000000000004b2f2000000000000000000000000eb08f243e5d3fcff26a9e38ae5520a669f4019d00000000000000000000000009f3b8679c73c2fef8b59b4f3444d4e156fb70aa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005425890298aed601595a70ab815c96711a31bc65000000000000000000000000caca21779c68af9fff7b601e9b478ada652bfef500000000000000000000000000000000000000000000000000000000000b006b000000000000000000000000fa3dad2778282e230dac3fd5bac2f44cb3612de2";
    const attestation = "0xffac426192817120fc421ae9035c61be57b90484483cb7e2de2d8447f149081e4df242959066b26d6cea09059ed7f6be9579303aa645357ab27801003ca295841c11e3c70cf1e6dd51caa47a7ae54a603d76b7e3459b83481c05336e40aec6a1ae0fa3a8c4b9caa16e3a9bf6324130b73f7797394efb22ebe11a22ef0e5bc92b581c";

    const receiveUsdc = await CrossCenter.receiveUSDC(
        message,
        attestation
    );
    const receiveUsdcTx=await receiveUsdc.wait();
    console.log("receiveUsdcTx:", receiveUsdcTx.hash);

    // const ERC20Contract=new ethers.Contract(USDCAddress, ERC20ABI.abi, owner);

    // const transferUsdc = await ERC20Contract.transfer(market, 2000000n);  //2 usdc
    // await transferUsdc.wait();
    // console.log("transferUsdc success");
    // const balance=await CrossCenter.getTokenBalance(USDCAddress, market);
    // console.log("USDC balance:", balance);
    // const marketContract = new ethers.Contract(market, VineAaveL2ABI.abi, manager);
    // const inOpSupply= await marketContract.inL2Supply(
    //     aavePool,
    //     opUSDC,
    //     balance
    // );
    // const inOpSupplyTx=await inOpSupply.wait();
    // console.log("inOpSupply:", inOpSupplyTx);

    // const currentBlock = await provider.getBlockNumber();
    // console.log("当前区块高度:", currentBlock);

    // const L2WithdrawAndCrossUSDCParams={
    //     destinationDomain: 3,
    //     inputBlock: currentBlock,
    //     l2Pool: aavePool,
    //     ausdc: opAUSDC,
    //     usdc: opUSDC
    // };
    
    // const ausdcBalance=await CrossCenter.getTokenBalance(L2WithdrawAndCrossUSDCParams.ausdc, market);
    // console.log("AUSDCbalance:", ausdcBalance);
    // if(ausdcBalance > 10000n){
    //     const l2WithdrawAndCrossUSDC = await managerMarketContract.l2WithdrawAndCrossUSDC(
    //         L2WithdrawAndCrossUSDCParams
    //     );
    //     const l2WithdrawAndCrossUSDCtx=await l2WithdrawAndCrossUSDC.wait();
    //     console.log("l2WithdrawAndCrossUSDC:", l2WithdrawAndCrossUSDCtx);
    // }


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});