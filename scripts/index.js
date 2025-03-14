const hre = require("hardhat");
const CoreCrossCenterABI=require("../artifacts/contracts/core/CoreCrossCenter.sol/CoreCrossCenter.json");
const CrossCenterABI=require("../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");
const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");

const Set=require('../set.json');
const fs = require('fs'); 

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("manager:", manager.address);
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

    // await sendETH(manager.address, "0.03");

    const feeManager = owner.address;
    const caller = manager.address;

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

    config.timestamp = new Date().toISOString();
    
    let GovernanceAddress;
    let CrossCenterAddress;
    let thisCrossCenterABI;
    let thisGovernanceABI;
    if (chainId === 43113n) {
        GovernanceAddress = config.Deployed.Governance;
        thisGovernanceABI = GovernanceABI.abi;
        CrossCenterAddress = config.Deployed.CoreCrossCenter;
        thisCrossCenterABI = CoreCrossCenterABI.abi;
    } else{
        GovernanceAddress = config.Deployed.VineHookCenter;
        thisGovernanceABI = VineHookCenterABI.abi;
        CrossCenterAddress = config.Deployed.CrossCenter;
        thisCrossCenterABI = CrossCenterABI.abi;
    }

    const managerGovernance = new ethers.Contract(GovernanceAddress, thisGovernanceABI, manager);
    const managerCrossCenter = new ethers.Contract(CrossCenterAddress, thisCrossCenterABI, manager);
    async function GetIndex(curatorId, destDomainId, targetHook){
        const getDestChainValidHooks=await managerGovernance.getDestChainValidHooks(curatorId, destDomainId);
        console.log("getDestChainValidHooks:", getDestChainValidHooks[0]);
        let index;
        for(let i=0;i<getDestChainValidHooks[0].length;i++){
            const bytesHook = await managerCrossCenter.addressToBytes32(targetHook);
            console.log("bytesHook:", bytesHook);
            if(getDestChainValidHooks[0][i]===bytesHook){
                index = i;
            }
        }
        console.log("index:", index);
        return index;
    }
    await GetIndex(1n, 3n, Set["Arbitrum_Sepolia"].Deployed.VineUniswapHook0);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});