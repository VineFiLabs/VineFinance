const hre = require("hardhat");
const fs = require('fs');
const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI=require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineAaveV3LendMainFactory02ABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain02Factory.sol/VineAaveV3LendMain02Factory.json");
const VineAaveV3LendMainFactory01ABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain01Factory.sol/VineAaveV3LendMain01Factory.json");
const VineInL2LendFactoryABI=require("../artifacts/contracts/hook/aave/VineInL2LendFactory.sol/VineInL2LendFactory.json");
const VineInETHLendFactoryABI=require("../artifacts/contracts/hook/aave/VineInETHLendFactory.sol/VineInETHLendFactory.json");
const Set=require('../set.json');

//avax fuji VineAaveV3LendMainFactory02: 0x8223243EcafEf58D7f31Fd29c566F64a4f8D1db2
//avax fuji hook: 0x5abb6d746bC98574957970D55F8E0F60DC64f9A7

//Arb Sepolia VineInL2LendFactory: 0xA1986A7A9979D0D75bDc79a8C484B9ac524e8a3d
//arb sepolia hook: 0x60F586f2588013AD6E36D91FB38bC1A303377f06

//Op Sepolia VineInL2LendFactory: 0x8D9Fedaf635DCE49D60503559314AEe2d31FcC15
//Op Sepolia hook: 0x65dcc8d9Ea4D360b8555a8e8C9080655ac634B2c

//Base Sepolia VineInL2LendFactory: 0x5137Fb1ad684Ec62e99722180890d237B39409Aa
//Base Sepolia hook: 0xfdf402929897331BCd250912A6502bcd4ede8ADe

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

      // const VineAaveV3LendMain02FactoryAddress = "0x8223243EcafEf58D7f31Fd29c566F64a4f8D1db2";
      const ManagerFactory=new ethers.Contract(VineAaveV3LendMain02FactoryAddress, VineAaveV3LendMainFactory02ABI.abi, manager);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address, "Vine USDC Share", "V-USDC-SHARE");
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0n);
      console.log("Hook:", getUserIdToHook);
      config.Deployed.VineAaveV3LendMain02Factory = VineAaveV3LendMain02FactoryAddress;
      config.Deployed.VineAaveV3LendMain02Hook0 = getUserIdToHook;
    }else if(chainId === 11155111n){
      const vineInETHLendFactory = await ethers.getContractFactory("VineInETHLendFactory");
      const VineInETHLendFactory = await vineInETHLendFactory.deploy(config.Deployed.VineHookCenter);
      const VineInETHLendFactoryAddress = await VineInETHLendFactory.target;
      console.log("VineInETHLendFactory Address:",VineInETHLendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInETHLendFactoryAddress, VineInETHLendFactoryABI.abi, manager);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0);
      console.log("Hook:", getUserIdToHook);
      config.Deployed.VineInETHLendFactory = VineInETHLendFactoryAddress;
      config.Deployed.VineInETHLendHook0 = getUserIdToHook;
    }else{
      const vineInL2LendFactory = await ethers.getContractFactory("VineInL2LendFactory");
      const VineInL2LendFactory = await vineInL2LendFactory.deploy(config.Deployed.VineHookCenter);
      const VineInL2LendFactoryAddress = await VineInL2LendFactory.target;
      console.log("VineInL2LendFactory Address:",VineInL2LendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInL2LendFactoryAddress, VineInL2LendFactoryABI.abi, manager);

      const vineHookCenter=new ethers.Contract(config.Deployed.VineHookCenter, VineHookCenterABI.abi, manager);
      // const getCuratorToId=await vineHookCenter.getCuratorToId(manager.address);
      // console.log("getCuratorToId:", getCuratorToId);
      const getMarketInfo=await vineHookCenter.getMarketInfo(0n);
      console.log("getMarketInfo:", getMarketInfo);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0);
      console.log("Hook:", getUserIdToHook);
      config.Deployed.VineInL2LendFactory = VineInL2LendFactoryAddress;
      config.Deployed.VineInL2LendHook0 = getUserIdToHook;
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