const hre = require("hardhat");
const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineAaveV3LendMainFactoryABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMainFactory.sol/VineAaveV3LendMainFactory.json");
const VineInL2LendFactoryABI=require("../artifacts/contracts/hook/aave/VineInL2LendFactory.sol/VineInL2LendFactory.json");
const VineInETHLendFactoryABI=require("../artifacts/contracts/hook/aave/VineInETHLendFactory.sol/VineInETHLendFactory.json");
const Set=require('../set.json');

//Arb Sepolia VineAaveV3LendMainFactory: 0x4d354C90651B07Be872fC0205AA4D1CD7630e2e5
//arb sepolia hook: 0xAe6271f75b159e00203A8b9f97Dc3E3812d19468

//Op Sepolia VineInL2LendFactory: 0x83527e33C2F7D13DeBe578Ff0C926b121c46c7dc
//Op Sepolia hook: 0xd409d1De3c77f00781bbD1546e2B4a922E75b83F

//Base Sepolia VineInL2LendFactory: 0x0db31d955A6e6DB2F35BF5f27C5D913CdF3E6e4C
//Base Sepolia hook: 0x44fa87860fAc0866eCb228677a07a7143E9ad003

//Sepolia VineInETHLendFactory: 0x50e8480F2Ca26371378F14673085D36730003600
//Sepolia hook: 0xA4d26e3adC27DC96d0cfA1a7295b5cFE1B13A963
async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
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

  // await sendETH(manager.address, "0.1");

    const arbGovernance="0x7fdF06F59a4Fa429c0Cee56d7009624bdF396f90";  //arb sepolia
    const opVineHookCenter="0x88105C02c8c803032D0092aD48373324d0559d48";  //op sepolia
    const baseVineHookCenter="0xE3940D2eeeb6920DB9565c4E3c5944888Ca93eab";  //base sepolia
    const sepoliaVineHookCenter="0xAa98C14031AF07647547bE1c7A24715EF0784472";  //sepolia

    if(chainId === 42161n || chainId === 421614n){
      const vineAaveV3LendMainFactory = await ethers.getContractFactory("VineAaveV3LendMainFactory");
      const VineAaveV3LendMainFactory = await vineAaveV3LendMainFactory.deploy(arbGovernance);
      const VineAaveV3LendMainFactoryAddress = await VineAaveV3LendMainFactory.target;
      console.log("VineAaveV3LendMainFactory Address:",VineAaveV3LendMainFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineAaveV3LendMainFactoryAddress, VineAaveV3LendMainFactoryABI.abi, manager);
      const governanceAddress = await ManagerFactory.govern();
      console.log("governanceAddress:", governanceAddress);
      const Governance = new ethers.Contract(governanceAddress, GovernanceABI.abi, manager);
      const getMarketInfo = await Governance.getMarketInfo(0);
      console.log("getMarketInfo:", getMarketInfo);
      const getCuratorToId = await Governance.getCuratorToId(manager.address);
      console.log("getCuratorToId:", getCuratorToId);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address, "Vine USDC Share", "V-USDC-SHARE");
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0);
      console.log("Hook:", getUserIdToHook);
    }else if(chainId === 10n || chainId === 11155420n){
      const vineInL2LendFactory = await ethers.getContractFactory("VineInL2LendFactory");
      const VineInL2LendFactory = await vineInL2LendFactory.deploy(opVineHookCenter);
      const VineInL2LendFactoryAddress = await VineInL2LendFactory.target;
      console.log("VineInL2LendFactory Address:",VineInL2LendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInL2LendFactoryAddress, VineInL2LendFactoryABI.abi, manager);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0);
      console.log("Hook:", getUserIdToHook);
    }else if(chainId === 8453n || chainId === 84532n){
      const vineInL2LendFactory = await ethers.getContractFactory("VineInL2LendFactory");
      const VineInL2LendFactory = await vineInL2LendFactory.deploy(baseVineHookCenter);
      const VineInL2LendFactoryAddress = await VineInL2LendFactory.target;
      console.log("VineInL2LendFactory Address:",VineInL2LendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInL2LendFactoryAddress, VineInL2LendFactoryABI.abi, manager);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0);
      console.log("Hook:", getUserIdToHook);
    }else if(chainId === 1n || chainId === 11155111n){
      const vineInETHLendFactory = await ethers.getContractFactory("VineInETHLendFactory");
      const VineInETHLendFactory = await vineInETHLendFactory.deploy(sepoliaVineHookCenter);
      const VineInETHLendFactoryAddress = await VineInETHLendFactory.target;
      console.log("VineInETHLendFactory Address:",VineInETHLendFactoryAddress);

      const ManagerFactory=new ethers.Contract(VineInETHLendFactoryAddress, VineInETHLendFactoryABI.abi, manager);

      const createMainMarket = await ManagerFactory.createMarket(manager.address, manager.address);
      await createMainMarket.wait();
      console.log("createMainMarket success");
      const getUserIdToHook=await ManagerFactory.getUserIdToHook(0);
      console.log("Hook:", getUserIdToHook);
    }else{
        throw("Not chain id")
    }
    

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});