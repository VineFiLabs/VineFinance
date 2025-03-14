const hre = require("hardhat");

const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI=require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const CoreCrossCenterABI=require("../artifacts/contracts/core/CoreCrossCenter.sol/CoreCrossCenter.json");
const CrossCenterABI=require("../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const Set=require('../set.json');

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
      const CrossCenter=new ethers.Contract(config.Deployed.CoreCrossCenter, CoreCrossCenterABI.abi, manager);
      const factorys=[config.Deployed.VineAaveV3LendMain02Factory];
      const states=['0x01'];
      const batchSetValidCaller = await CrossCenter.batchSetValidCaller(factorys, states);
      await batchSetValidCaller.wait();
      console.log("batchSetValidCaller success");
    }else if(chainId === 421614n){
        const CrossCenter=new ethers.Contract(config.Deployed.CrossCenter, CrossCenterABI.abi, manager);
        const factorys=[config.Deployed.VineInL2LendFactory, config.Deployed.VineUniswapFactory];
        const states=['0x01', '0x01'];
        const batchSetValidCaller = await CrossCenter.batchSetValidCaller(factorys, states);
        await batchSetValidCaller.wait();
        console.log("batchSetValidCaller success");
    }else if(chainId === 84532n){
      const CrossCenter=new ethers.Contract(config.Deployed.CrossCenter, CrossCenterABI.abi, manager);
      const factorys=[config.Deployed.VineInL2LendFactory, config.Deployed.VineMorphoFactory];
      const states=['0x01', '0x01'];
      const batchSetValidCaller = await CrossCenter.batchSetValidCaller(factorys, states);
      await batchSetValidCaller.wait();
      console.log("batchSetValidCaller success");
    }else{
        const CrossCenter=new ethers.Contract(config.Deployed.CrossCenter, CrossCenterABI.abi, manager);
        const factorys=[config.Deployed.VineInL2LendFactory];
        const states=['0x01'];
        const batchSetValidCaller = await CrossCenter.batchSetValidCaller(factorys, states);
        await batchSetValidCaller.wait();
        console.log("batchSetValidCaller success");
    }
    

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});