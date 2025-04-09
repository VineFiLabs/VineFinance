const hre = require("hardhat");
const fs = require('fs');
const GovernanceABI=require("../../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI=require("../../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineAaveV3LendMainFactory02ABI=require("../../artifacts/contracts/hook/aave/VineAaveV3LendMain02Factory.sol/VineAaveV3LendMain02Factory.json");
const VineAaveV3LendMainFactory01ABI=require("../../artifacts/contracts/hook/aave/VineAaveV3LendMain01Factory.sol/VineAaveV3LendMain01Factory.json");
const VineInL2LendFactoryABI=require("../../artifacts/contracts/hook/aave/VineInL2LendFactory.sol/VineInL2LendFactory.json");
const VineInL1LendFactoryABI=require("../../artifacts/contracts/hook/aave/VineInL1LendFactory.sol/VineInL1LendFactory.json");
const Set=require('../../set.json');

//avax fuji VineAaveV3LendMainFactory02: 
//avax fuji hook: 

//Arb Sepolia VineInL2LendFactory: 
//arb sepolia hook: 

//Op Sepolia VineInL2LendFactory: 
//Op Sepolia hook: 

//Base Sepolia VineInL2LendFactory: 
//Base Sepolia hook: 

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    let config;
    let networkName;
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
    }else if(chainId === 11155420n){
      config = Set.Op_Sepolia;
      networkName = "Op_Sepolia";
    }else if(chainId === 421614n){
      config = Set.Arbitrum_Sepolia;
      networkName = "Arbitrum_Sepolia";
    }else if(chainId === 84532n){
      config = Set.Base_Sepolia;
      networkName = "Base_Sepolia";
    }else{
      throw("Not chain id");
    }

    if(chainId === 43113n){
      const vineAaveV3LendMain02Factory = await ethers.getContractFactory("VineAaveV3LendMain02Factory");
      const VineAaveV3LendMain02Factory = await vineAaveV3LendMain02Factory.deploy(config.Deployed.Governance);
      const VineAaveV3LendMain02FactoryAddress = await VineAaveV3LendMain02Factory.target;
      console.log("VineAaveV3LendMain02Factory Address:",VineAaveV3LendMain02FactoryAddress);

      // const VineAaveV3LendMain02FactoryAddress = "";
      const ManagerFactory=new ethers.Contract(VineAaveV3LendMain02FactoryAddress, VineAaveV3LendMainFactory02ABI.abi, manager);

      const Governance=new ethers.Contract(config.Deployed.Governance, GovernanceABI.abi, manager);
      const getCuratorToId=await Governance.getCuratorId(manager.address);
      console.log("getCuratorToId:", getCuratorToId);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const curatorIdToHookMarketInfo=await ManagerFactory.CuratorIdToHookMarketInfo(getCuratorToId);
      console.log("Hook:", curatorIdToHookMarketInfo);
      config.Deployed.VineAaveV3LendMain02Factory = VineAaveV3LendMain02FactoryAddress;
      config.Deployed[`VineAaveV3LendMain02Hook${getCuratorToId}`] = curatorIdToHookMarketInfo[1];

    }else if(chainId === 11155111n){
      const vineInL1LendFactory = await ethers.getContractFactory("VineInL1LendFactory");
      const VineInL1LendFactory = await vineInL1LendFactory.deploy(config.Deployed.VineHookCenter);
      const VineInL1LendFactoryAddress = await VineInL1LendFactory.target;
      console.log("VineInETHLendFactory Address:",VineInL1LendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInL1LendFactoryAddress, VineInL1LendFactoryABI.abi, manager);

      const vineHookCenter=new ethers.Contract(config.Deployed.VineHookCenter, VineHookCenterABI.abi, manager);
      const getCuratorToId=await vineHookCenter.getCuratorId(manager.address);
      console.log("getCuratorToId:", getCuratorToId);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");

      const curatorIdToHookMarketInfo=await ManagerFactory.CuratorIdToHookMarketInfo(0);
      console.log("Hook:", curatorIdToHookMarketInfo);
      config.Deployed.VineInL1LendFactory = VineInL1LendFactoryAddress;
      config.Deployed[`VineInL1LendHook${getCuratorToId}`] = curatorIdToHookMarketInfo[1];
    }else{
      const vineInL2LendFactory = await ethers.getContractFactory("VineInL2LendFactory");
      const VineInL2LendFactory = await vineInL2LendFactory.deploy(config.Deployed.VineHookCenter);
      const VineInL2LendFactoryAddress = await VineInL2LendFactory.target;
      console.log("VineInL2LendFactory Address:",VineInL2LendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInL2LendFactoryAddress, VineInL2LendFactoryABI.abi, manager);

      const vineHookCenter=new ethers.Contract(config.Deployed.VineHookCenter, VineHookCenterABI.abi, manager);
      const getCuratorToId=await vineHookCenter.getCuratorId(manager.address);
      console.log("getCuratorToId:", getCuratorToId);

      const getMarketInfo=await vineHookCenter.getMarketInfo(getCuratorToId);
      console.log("getMarketInfo:", getMarketInfo);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const curatorIdToHookMarketInfo=await ManagerFactory.CuratorIdToHookMarketInfo(getCuratorToId);
      console.log("Hook:", curatorIdToHookMarketInfo);
      config.Deployed.VineInL2LendFactory = VineInL2LendFactoryAddress;
      config.Deployed[`VineInL2LendHook${getCuratorToId}`] = curatorIdToHookMarketInfo[1];
    }
    const setPath = './set.json';
    const currentSet = JSON.parse(fs.readFileSync(setPath, 'utf8'));
    currentSet[networkName] = config;
    fs.writeFileSync(setPath, JSON.stringify(currentSet, null, 2));
    console.log("set.json updated");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});